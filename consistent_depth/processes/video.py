"""
Video processing
"""

# from types import SimpleNamespace
from glob import glob
from os import makedirs
from os.path import basename, isdir, isfile, join, splitext

import ffmpeg
from PIL import Image


class Frames:
    """
    Class handling images from frames extracted video.

    path use glob style path.
    """

    PNG = "png"
    JPG = "jpg"
    JPEG = "jpeg"
    RAW = "raw"

    def __init__(self, path: str, format: str):
        if (
            format != self.PNG
            and format != self.JPEG
            and format != self.JPG
            and format != self.RAW
        ):
            raise TypeError("Format frames not usable.")
        self.format = format
        self.files = sorted(glob(path + f".{format}"))

    def get_nb(self):
        return len(self.files)

    def __iter__(self):
        for img in self.files:
            yield Image.open(img)


class FFMPEG:
    """
    Class Wrapper helps to use ffmpeg-python.
    """

    # TODO pass in properties.

    def __init__(self, video_path: str):
        if type(video_path) is not str:
            raise TypeError
        self.video_path = video_path
        self.__probe()

    def __probe(self):
        """
        Private method to probe video or
        """
        if isfile(self.video_path):
            self.__probe_video()
        if isdir(self.video_path):
            self.__probe_images()  # pragma: no cover

    def __probe_images(self):
        pass  # pragma: no cover

    def __probe_video(self):
        d = ffmpeg.probe(self.video_path)
        self.filename = basename(self.video_path)
        self.container = splitext(self.video_path)[-1].replace(".", "")
        self.type = "video"
        # self.format = SimpleNamespace(**d["format"])
        # self.streams = d["streams"]
        self.__get_parse_streams(d["streams"])

    def __get_parse_streams(self, streams):
        """
        Extract nb frames from a video file or count image file.
        """
        for stream in streams:
            if stream["codec_type"] == "video":
                self.nb_frames = int(stream["nb_frames"])
                self.width = int(stream["width"])
                self.height = int(stream["height"])
                self.format = stream["codec_name"]
                self.fps = int(stream["codec_time_base"].split("/")[-1])
                self.pixel_format = stream["pix_fmt"]

    def extract_frames(self, output: str, format="jpg", start=0, end=None):
        """
        Extract frames from a video file.
        """
        self.__extract_frames_errors(format, start, end)
        if end is None:
            end = self.nb_frames

        filename = self.filename.replace(splitext(self.video_path)[-1], "")
        length_naming = "-%0{}d".format(len(str(self.nb_frames)))
        frames_name = filename + length_naming + "." + format
        images_glob_name = join(output, filename + "-*")

        makedirs(output, exist_ok=True)
        (
            ffmpeg.input(self.video_path)
            .trim(start_frame=start, end_frame=end)
            .output(join(output, frames_name))
            .run()
        )

        frames = Frames(images_glob_name, format=format)
        if (end - start) != frames.get_nb():
            raise ValueError("Error during frames extraction")
        return frames

    def __extract_frames_errors(self, format, start, end):
        # Errors handling for extract frames method
        if self.type != "video":
            raise TypeError("Input must be a video.")
        if (
            format != Frames.PNG
            and format != Frames.JPEG
            and format != Frames.JPG
            and format != Frames.RAW
        ):
            raise ValueError('format must be "png" or "jpg"')
        if type(start) is not int:
            raise TypeError("start frame must be a integer.")
        if end is not None:
            if type(end) is not int:
                raise TypeError("end frame must be a integer.")
            if start > end:
                raise ValueError("Start frame musn't be upper to end frame.")
            if end > self.nb_frames:
                raise ValueError(
                    "End frames musn't upper to number frames of video."
                )
