import os
import urllib.request
import gzip
import shutil
import sys

def download_ffmpeg():
    # Statically compiled gzip build (27MB compressed, extracts to 78MB raw executable)
    url = "https://github.com/eugeneware/ffmpeg-static/releases/download/b5.0.1/win32-x64.gz"
    
    bin_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bin")
    os.makedirs(bin_dir, exist_ok=True)
    
    target_path = os.path.join(bin_dir, "ffmpeg.exe")
    gz_path = os.path.join(bin_dir, "ffmpeg.gz")
    
    if os.path.exists(target_path):
        print(f"ffmpeg.exe already exists at: {target_path}")
        return True
        
    print(f"Downloading static Windows x64 FFmpeg archive from {url}...")
    print(f"Size: ~27MB...")
    
    try:
        def report_progress(block_num, block_size, total_size):
            downloaded = block_num * block_size
            percent = min(100, int(downloaded * 100 / total_size))
            sys.stdout.write(f"\rDownload Progress: {percent}% [{downloaded}/{total_size} bytes]")
            sys.stdout.flush()

        urllib.request.urlretrieve(url, gz_path, reporthook=report_progress)
        print("\nDownload completed. Decompressing archive...")
        
        # Decompress gzip file to raw binary
        with gzip.open(gz_path, 'rb') as f_in:
            with open(target_path, 'wb') as f_out:
                shutil.copyfileobj(f_in, f_out)
                
        # Delete temporary .gz archive
        if os.path.exists(gz_path):
            os.remove(gz_path)
            
        print(f"Extraction successful! Static binary ready at {target_path}")
        return True
    except Exception as e:
        print(f"\n[ERROR] Failed to download or extract ffmpeg: {str(e)}")
        # Clean up files if failed
        for path in [target_path, gz_path]:
            if os.path.exists(path):
                try:
                    os.remove(path)
                except:
                    pass
        return False

if __name__ == "__main__":
    download_ffmpeg()
