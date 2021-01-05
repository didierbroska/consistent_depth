"""
Tests FFMPEG class from processes video module.
"""

import re
from glob import glob
from os.path import join
from shutil import rmtree

import pytest

from consistent_depth.processes.video import FFMPEG, Frames


def test_ffmpeg_probe_videofile(video_file1):
    video1 = FFMPEG(video_file1)

    assert video1.filename == "demo_video1.mp4"
    assert video1.container == "mp4"
    assert video1.nb_frames == 92
    assert video1.width == 1080
    assert video1.height == 1920
    assert video1.format == "h264"
    assert video1.fps == 60
    assert video1.pixel_format == "yuv420p"


def test_ffmpeg_commons_errors():
    """
    Testing errors handling.
    """
    with pytest.raises(TypeError):
        # Error type input
        FFMPEG(1)


def test_ffmpeg_extract_frames_errors(data_folder, video_file1, monkeypatch):
    """
    Tests FFMPEG extract frames methods.
    """
    results = join(data_folder, "results")
    video1 = FFMPEG(video_file1)
    # Error format FIXME
    with pytest.raises(ValueError):
        video1.extract_frames("foo", format="bar")

    # FIXME when handling images folder and change Exception type
    video1.type = "images"
    with pytest.raises(TypeError):
        video1.extract_frames("foo")

    video1.type = "video"
    with pytest.raises(ValueError):
        video1.extract_frames(results, start=10, end=9)

    with pytest.raises(TypeError):
        video1.extract_frames(results, start="foo")

    with pytest.raises(TypeError):
        video1.extract_frames(results, end="foo")

    with pytest.raises(ValueError):
        video1.extract_frames(results, end=93)

    with monkeypatch.context() as m:

        def get_nb_fake(*args, **kwargs):
            return 91
        m.setattr(Frames, "get_nb", get_nb_fake)
        with pytest.raises(ValueError):
            video1.extract_frames(results)


def test_ffmpeg_extract_frames(data_folder, video_file1):
    results = join(data_folder, "results")
    video1 = FFMPEG(video_file1)

    frames = video1.extract_frames(results)
    assert frames.get_nb() == 92
    imgs = glob(join(results, "*"))
    assert len(imgs) == 92
    for img in imgs:
        assert re.search(r"-[0-9]+(.jpg)$", img)
    rmtree(results)

    frames = video1.extract_frames(results, format="png", start=5)
    assert frames.get_nb() == 92 - 5
    imgs = glob(join(results, "*"))
    assert len(imgs) == 92 - 5
    for img in imgs:
        assert re.search(r"-[0-9]+(.png)$", img)
    rmtree(results)

    frames = video1.extract_frames(results, format="jpeg", start=5, end=10)
    assert frames.get_nb() == 5
    imgs = glob(join(results, "*"))
    assert len(imgs) == 5
    for img in imgs:
        assert re.search(r"-[0-9]+(.jpeg)$", img)
    rmtree(results)

    frames = video1.extract_frames(results, format="raw", start=5, end=10)
    assert frames.get_nb() == 5
    imgs = glob(join(results, "*"))
    assert len(imgs) == 5
    for img in imgs:
        assert re.search(r"-[0-9]+(.raw)$", img)
    rmtree(results)
