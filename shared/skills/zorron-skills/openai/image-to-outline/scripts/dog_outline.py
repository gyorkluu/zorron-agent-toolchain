import numpy as np
import os
import sys
from PIL import Image, ImageFilter

def load_image(path, pad=20):
    """
    加载图像，完美处理透明通道（转换为白色背景），并增加安全边距。
    """
    if not os.path.exists(path):
        raise FileNotFoundError(f"Image not found at path: {path}")
    img = Image.open(path)
    
    # 增加白色留白边框，防止原图贴边时边缘切断产生黑影
    padded_size = (img.width + pad * 2, img.height + pad * 2)
    bg = Image.new("RGB", padded_size, (255, 255, 255))
    
    if img.mode in ("RGBA", "LA") or (img.mode == "P" and "transparency" in img.info):
        alpha = img.split()[-1]
        bg.paste(img, (pad, pad), mask=alpha)
    else:
        bg.paste(img.convert("RGB"), (pad, pad))
    return bg

def run_dog(img, threshold=40, sigma1=1.0, sigma2=2.0, p=0.99, dilate_pixels=1):
    """
    高斯差分 (DoG) 精细线稿提取通用方法。
    """
    # 1. 转换为灰度
    gray_img = img.convert("L")
    
    # 2. 预中值滤波，抹平微小噪点和渐变阴影
    gray_smooth = gray_img.filter(ImageFilter.MedianFilter(3))
    
    # 3. 计算双尺度高斯模糊
    blur1 = np.array(gray_smooth.filter(ImageFilter.GaussianBlur(sigma1)), dtype=np.float32)
    blur2 = np.array(gray_smooth.filter(ImageFilter.GaussianBlur(sigma2)), dtype=np.float32)
    
    # 4. 高斯差分相减
    dog = blur1 - p * blur2
    
    # 5. 二值化
    dog_normalized = np.ones_like(dog, dtype=np.uint8) * 255
    # 低于负阈值则判定为强边缘（线稿）
    dog_normalized[dog < -abs(threshold / 40.0)] = 0
    
    # 6. 后处理平滑
    dog_img = Image.fromarray(dog_normalized)
    dog_img = dog_img.filter(ImageFilter.MedianFilter(3))
    
    # 7. 基于 NumPy 的简易膨胀做线宽加粗
    out_arr = np.array(dog_img)
    if dilate_pixels > 0:
        final_arr = np.copy(out_arr)
        for dy in range(-dilate_pixels, dilate_pixels + 1):
            for dx in range(-dilate_pixels, dilate_pixels + 1):
                if dx == 0 and dy == 0:
                    continue
                shifted = np.roll(np.roll(out_arr, dy, axis=0), dx, axis=1)
                final_arr = np.minimum(final_arr, shifted)
        final_img = Image.fromarray(final_arr)
    else:
        final_img = dog_img
        
    return final_img

def convert_image_to_outline(input_path, output_path, threshold=40, pad=20, dilate_pixels=1):
    """
    一键将图像转为高精度去噪线稿通用接口。
    """
    img = load_image(input_path, pad=pad)
    outline = run_dog(img, threshold=threshold, dilate_pixels=dilate_pixels)
    outline.save(output_path)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python dog_outline.py <input_path> <output_path> [threshold: default 40] [pad: default 20] [dilate: default 1]")
        sys.exit(1)
        
    in_p = sys.argv[1]
    out_p = sys.argv[2]
    thresh = int(sys.argv[3]) if len(sys.argv) > 3 else 40
    padding = int(sys.argv[4]) if len(sys.argv) > 4 else 20
    dilate = int(sys.argv[5]) if len(sys.argv) > 5 else 1
    
    try:
        convert_image_to_outline(in_p, out_p, threshold=thresh, pad=padding, dilate_pixels=dilate)
        print(f"Successfully converted outline -> {out_p}")
    except Exception as e:
        print(f"Error during conversion: {e}")
        sys.exit(1)
