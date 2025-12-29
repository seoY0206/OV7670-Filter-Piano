import sys
sys.stdout.reconfigure(line_buffering=True)

import serial
from pynput import keyboard
import pygame
import threading
import time

# UART 설정
ser = serial.Serial('COM8', 115200, timeout=0.1)

# Pygame mixer 초기화
pygame.mixer.init()
pygame.mixer.set_num_channels(9)   # ★ 추가!

# 사운드 로딩
NOTE_SND = {
    0: pygame.mixer.Sound(r"도레미파솔라시도/C4.mp3"),
    1: pygame.mixer.Sound(r"도레미파솔라시도/D4.mp3"),
    2: pygame.mixer.Sound(r"도레미파솔라시도/E4.mp3"),
    3: pygame.mixer.Sound(r"도레미파솔라시도/F4.mp3"),
    4: pygame.mixer.Sound(r"도레미파솔라시도/G4.mp3"),
    5: pygame.mixer.Sound(r"도레미파솔라시도/A4.mp3"),
    6: pygame.mixer.Sound(r"도레미파솔라시도/B4.mp3"),
    7: pygame.mixer.Sound(r"도레미파솔라시도/C5.mp3"),
    8: None
}

# 🔥 방법 2: 각 음마다 전용 채널 하나씩
note_channels = {i: pygame.mixer.Channel(i) for i in NOTE_SND.keys()}


# ------------------------------------------------------
# RX: 들어오는 대로 즉시 재생
# ------------------------------------------------------
def uart_receive_thread():
    while True:
        data = ser.read(1)
        if data:
            val = data[0]
            print("[RX]", val, flush=True)

            snd = NOTE_SND.get(val)
            if snd:
                ch = note_channels[val]  # 전용 채널
                ch.stop()               # 이전 소리 중단
                ch.play(snd)            # 새로 재생


rx_thread = threading.Thread(target=uart_receive_thread, daemon=True)
rx_thread.start()


# ------------------------------------------------------
# TX: 1초마다 최신 값 전송 (형님 요청대로)
# ------------------------------------------------------
latest_tx_value = None
tx_lock = threading.Lock()

def tx_timer_thread():
    global latest_tx_value
    while True:
        time.sleep(0.02)  # ★ 1초마다 보냄 (형님 요구사항)
        with tx_lock:
            if latest_tx_value is not None:
                val = latest_tx_value
                latest_tx_value = None
            else:
                continue

        print("[TX 1sec] send:", val)
        ser.write(bytes([val]))


tx_thread = threading.Thread(target=tx_timer_thread, daemon=True)
tx_thread.start()


# ------------------------------------------------------
# 키 입력 처리
# ------------------------------------------------------
def on_press(key):
    global latest_tx_value

    try:
        if key.char and key.char.lower() == 'a':
            print("A pressed → request send 0x01", flush=True)
            with tx_lock:
                latest_tx_value = 1
    except AttributeError:
        pass


def on_release(key):
    if key == keyboard.Key.esc:
        print("종료합니다.", flush=True)
        ser.close()
        return False

    if hasattr(key, 'char') and key.char and key.char.lower() == 'a':
        print("A released", flush=True)


listener = keyboard.Listener(on_press=on_press, on_release=on_release)
listener.start()
listener.join()
