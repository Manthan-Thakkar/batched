import boto3
from boto3.s3.transfer import TransferConfig
from botocore.config import Config

MB = 1024 ** 2

# Tune multipart chunk size and concurrency for higher throughput
tconfig = TransferConfig(
    multipart_threshold=8 * MB,     # switch to multipart above this size
    multipart_chunksize=64 * MB,    # each part size (>= 5 MiB)
    max_concurrency=16,             # parallel uploads
    use_threads=True
)

# Optional: use Transfer Acceleration (bucket must have it enabled)
boto_cfg = Config(s3={"use_accelerate_endpoint": True})

s3 = boto3.client("s3", config=boto_cfg)  # drop config=boto_cfg if not using acceleration
s3.upload_file(
    Filename="/Users/manthanthakkar/Downloads/inovar-packaging-dion-label-2025-11-05-06-15.bak",
    Bucket="batched-manual-db-backup-bucket",
    Key="inovar-packaging-dion-label-pb.bak",
    Config=tconfig
)
print("Upload complete")