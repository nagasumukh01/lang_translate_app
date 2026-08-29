import os
import urllib.request
import sys

def download_cloudflared():
    url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe"
    
    bin_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bin")
    os.makedirs(bin_dir, exist_ok=True)
    
    target_path = os.path.join(bin_dir, "cloudflared.exe")
    
    if os.path.exists(target_path):
        print(f"cloudflared.exe already exists at: {target_path}")
        return True
        
    print(f"Downloading static cloudflared.exe from {url}...")
    print(f"Size: ~15MB...")
    
    try:
        def report_progress(block_num, block_size, total_size):
            downloaded = block_num * block_size
            percent = min(100, int(downloaded * 100 / total_size))
            sys.stdout.write(f"\rDownload Progress: {percent}% [{downloaded}/{total_size} bytes]")
            sys.stdout.flush()

        urllib.request.urlretrieve(url, target_path, reporthook=report_progress)
        print("\nDownload completed successfully!")
        return True
    except Exception as e:
        print(f"\n[ERROR] Failed to download cloudflared: {str(e)}")
        if os.path.exists(target_path):
            try:
                os.remove(target_path)
            except:
                pass
        return False

if __name__ == "__main__":
    download_cloudflared()
