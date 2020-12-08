"""
Tests Frames class helps to handles image file extracted from a video.
"""

import pytest
from os.path import join

from consistent_depth.processes.video import Frames
from PIL.JpegImagePlugin import JpegImageFile


def test_frames(data_folder, frames_video1):
    """
    Testing Frames class
    """
    assert frames_video1.get_nb() == 92
    assert frames_video1.format == "jpg"

    with pytest.raises(TypeError):
        Frames("foo", format="pdf")

    frames = Frames(join(data_folder, "results", "*"), format="jpg")
    assert frames.get_nb() == 92
    frames = Frames(join(data_folder, "results", "*"), format="png")
    assert frames.get_nb() == 0

    for img in frames_video1:
        assert type(img) == JpegImageFile
