"""
Mainconfiguration for PyTest
"""

import os
import os.path
import shutil

import gdown
import pytest

from consistent_depth.processes.video import FFMPEG

GDRIVE_LINK = "https://drive.google.com/uc?id="

DATA_FOLDER = os.path.join("tests", "data")
os.makedirs(DATA_FOLDER, exist_ok=True)

RESULTS_PATH = os.path.join(DATA_FOLDER, "results")
VIDEO_TEST_1 = (
    GDRIVE_LINK + "1GFEId2xlF2HE5HHKaaT1njWKQQczpbqw",
    os.path.join(DATA_FOLDER, "demo_video1.zip"),
    os.path.join(DATA_FOLDER, "demo_video1.mp4"),
)
VIDEO_TEST_2 = (
    GDRIVE_LINK + "1WRVl767Sg8hPkGu8PbYN5hvjNvxh8Dqn",
    os.path.join(DATA_FOLDER, "demo_video2.zip"),
    os.path.join(DATA_FOLDER, "demo_video2.mp4"),
)


@pytest.fixture
def data_folder():
    return DATA_FOLDER


@pytest.fixture
def video_file1():
    """
    Donwload video from Google Drive and return path for tests.
    """
    url, zip_path, video_path = VIDEO_TEST_1

    if not os.path.isfile(zip_path):
        gdown.download(url, zip_path, quiet=True)
    gdown.extractall(zip_path)

    yield os.path.abspath(video_path)

    os.remove(video_path)
    if os.path.isdir(RESULTS_PATH):
        shutil.rmtree(RESULTS_PATH)


@pytest.fixture
def video_file2():
    """
    Donwload video from Google Drive and return path for tests.
    """
    url, zip_path, video_path = VIDEO_TEST_2

    if not os.path.isfile(zip_path):
        gdown.download(url, zip_path, quiet=True)
    gdown.extractall(zip_path)

    yield os.path.abspath(video_path)

    os.remove(video_path)
    if os.path.isdir(RESULTS_PATH):
        shutil.rmtree(RESULTS_PATH)


@pytest.fixture
def frames_video1(video_file1):
    results = os.path.join(DATA_FOLDER, "results")
    video1 = FFMPEG(video_file1)
    yield video1.extract_frames(results)
    shutil.rmtree(results)
