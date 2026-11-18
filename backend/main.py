"""
Msm TubeMate - Python FastAPI Backend Engine
Organization: ORG: msm.movin 2022
Handles: Search, Link Parsing, Multi-tier Format Extraction (4K/2K/1080p/MP3), and Streaming.
"""

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import yt_dlp
import requests
import logging
import re

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("tubemate_api")

app = FastAPI(
    title="Msm TubeMate Extraction Engine",
    description="High-speed multi-platform media extraction API for Msm TubeMate (ORG: msm.movin 2022)",
    version="2.0.0"
)

# Enable CORS for Flutter Mobile & Web Clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ExtractRequest(BaseModel):
    url: str


def format_filesize(bytes_val: Optional[int]) -> str:
    if not bytes_val or bytes_val <= 0:
        return "Unknown"
    for unit in ['B', 'KB', 'MB', 'GB']:
        if bytes_val < 1024.0:
            return f"{bytes_val:.1f} {unit}"
        bytes_val /= 1024.0
    return f"{bytes_val:.1f} TB"


@app.get("/")
def health():
    return {
        "status": "online",
        "app": "Msm TubeMate",
        "copyright": "ORG: msm.movin 2022",
        "supported_platforms": ["YouTube", "Instagram", "Facebook", "Twitter/X", "WhatsApp", "TikTok"]
    }


@app.get("/api/search")
def search_media(q: str = Query(..., description="Search query keyword"), limit: int = Query(20, le=50)):
    """Search media via yt-dlp metadata without downloading bytes."""
    ydl_opts = {
        'quiet': True,
        'extract_flat': True,
        'no_warnings': True,
        'skip_download': True,
    }
    query_str = f"ytsearch{limit}:{q}"
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            res = ydl.extract_info(query_str, download=False)
            results = []
            for item in res.get('entries', []):
                if item:
                    results.append({
                        "id": item.get("id"),
                        "title": item.get("title", "Untitled"),
                        "channel": item.get("uploader") or item.get("channel") or "Unknown Channel",
                        "duration": item.get("duration", 0),
                        "view_count": item.get("view_count", 0),
                        "thumbnail": item.get("thumbnail") or f"https://i.ytimg.com/vi/{item.get('id')}/hqdefault.jpg",
                        "webpage_url": item.get("webpage_url") or f"https://www.youtube.com/watch?v={item.get('id')}",
                    })
            return {"success": True, "count": len(results), "results": results}
    except Exception as e:
        logger.error(f"Search failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/extract")
def extract_media(req: ExtractRequest):
    """
    Extracts comprehensive metadata, playlist items, and categorized
    multi-tier audio & video formats as specified in the PRD.
    """
    url = req.url.strip()
    if not url:
        raise HTTPException(status_code=400, detail="URL cannot be empty")

    ydl_opts = {
        'quiet': True,
        'no_warnings': True,
        'skip_download': True,
        'extract_flat': False,
    }

    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            if not info:
                raise ValueError("Unable to retrieve information for this URL")

            # 1. Check if Playlist
            if '_type' in info and info['_type'] == 'playlist':
                entries = []
                for idx, entry in enumerate(info.get('entries', [])):
                    if entry:
                        entries.append({
                            "index": idx + 1,
                            "id": entry.get("id"),
                            "title": entry.get("title", f"Track {idx + 1}"),
                            "duration": entry.get("duration", 0),
                            "thumbnail": entry.get("thumbnail") or "",
                            "url": entry.get("webpage_url") or entry.get("url") or f"https://www.youtube.com/watch?v={entry.get('id')}",
                        })
                return {
                    "success": True,
                    "is_playlist": True,
                    "title": info.get("title", "Playlist"),
                    "author": info.get("uploader") or info.get("channel") or "Unknown Author",
                    "item_count": len(entries),
                    "thumbnail": entries[0]["thumbnail"] if entries else "",
                    "entries": entries,
                }

            # 2. Single Video / Audio Processing
            title = info.get("title", "Untitled")
            thumbnail = info.get("thumbnail") or ""
            duration = info.get("duration", 0)
            uploader = info.get("uploader") or info.get("channel") or "Unknown"

            # Multi-tier Music / Audio Formats
            audio_formats = [
                {
                    "id": "audio_m4a_128k",
                    "label": "Fast M4A (128K)",
                    "extension": "m4a",
                    "category": "music",
                    "quality": "128K",
                    "note": "Best for mobile play",
                    "size_approx": format_filesize(int(duration * 128 * 1024 / 8)) if duration else "~4.5 MB",
                    "url": None
                },
                {
                    "id": "audio_mp3_70k",
                    "label": "Classic MP3 (70K)",
                    "extension": "mp3",
                    "category": "music",
                    "quality": "70K",
                    "note": "Low data mode",
                    "size_approx": format_filesize(int(duration * 70 * 1024 / 8)) if duration else "~2.5 MB",
                    "url": None
                },
                {
                    "id": "audio_mp3_128k",
                    "label": "Classic MP3 (128K)",
                    "extension": "mp3",
                    "category": "music",
                    "quality": "128K",
                    "note": "Standard compatibility",
                    "size_approx": format_filesize(int(duration * 128 * 1024 / 8)) if duration else "~5.0 MB",
                    "url": None
                },
                {
                    "id": "audio_mp3_160k",
                    "label": "Classic MP3 (160K)",
                    "extension": "mp3",
                    "category": "music",
                    "quality": "160K",
                    "note": "Balanced quality",
                    "size_approx": format_filesize(int(duration * 160 * 1024 / 8)) if duration else "~6.5 MB",
                    "url": None
                },
                {
                    "id": "audio_mp3_320k",
                    "label": "Classic MP3 (320K)",
                    "extension": "mp3",
                    "category": "music",
                    "quality": "320K",
                    "note": "High fidelity audio",
                    "size_approx": format_filesize(int(duration * 320 * 1024 / 8)) if duration else "~12.8 MB",
                    "url": None
                },
            ]

            # Video Formats
            video_formats = []
            seen_heights = set()
            for f in info.get("formats", []):
                h = f.get("height")
                vcodec = f.get("vcodec", "none")
                if h and vcodec != "none" and h not in seen_heights:
                    seen_heights.add(h)
                    size = f.get("filesize") or f.get("filesize_approx")
                    label = f"{h}p"
                    if h >= 2160:
                        label = "4K 2160p"
                    elif h >= 1440:
                        label = "2K 1440p"
                    elif h >= 1080:
                        label = "1080p Full HD"
                    elif h >= 720:
                        label = "720p HD"
                    elif h == 360:
                        label = "Fast (360p)"

                    video_formats.append({
                        "id": f.get("format_id"),
                        "label": label,
                        "height": h,
                        "extension": f.get("ext", "mp4"),
                        "category": "video",
                        "size_approx": format_filesize(size) if size else "Direct Stream",
                        "url": f.get("url")
                    })

            # Sort videos highest to lowest
            video_formats.sort(key=lambda x: x.get("height", 0), reverse=True)

            return {
                "success": True,
                "is_playlist": False,
                "id": info.get("id"),
                "title": title,
                "author": uploader,
                "duration": duration,
                "thumbnail": thumbnail,
                "webpage_url": url,
                "audio_formats": audio_formats,
                "video_formats": video_formats
            }
    except Exception as e:
        logger.error(f"Extraction failed: {e}")
        raise HTTPException(status_code=400, detail=str(e))


@app.get("/api/download-stream")
def download_stream(url: str = Query(...), format_id: Optional[str] = Query(None)):
    """Direct stream proxy serving Content-Length headers for accurate Flutter progress bars."""
    ydl_opts = {
        'quiet': True,
        'format': format_id if format_id else 'best',
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=False)
            stream_url = info.get("url")
            if not stream_url:
                raise ValueError("Direct stream URL not available")

            r = requests.get(stream_url, stream=True, headers={'User-Agent': 'Mozilla/5.0'})
            content_length = r.headers.get('content-length')
            headers = {
                'Content-Disposition': f'attachment; filename="{info.get("title", "media")}.{info.get("ext", "mp4")}"',
            }
            if content_length:
                headers['Content-Length'] = content_length

            return StreamingResponse(
                r.iter_content(chunk_size=64 * 1024),
                media_type=r.headers.get('content-type', 'application/octet-stream'),
                headers=headers
            )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
