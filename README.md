# 🎹 Filter Piano - OV7670(VGA) + I2C + Python

> FPGA에서 OV7670 카메라부터 실시간 영상 처리, 피아노 인터페이스 및 필터 효과를 통합 구현한 하드웨어 기반 영상 시스템

![Camera](https://img.shields.io/badge/Hardware-OV7670-red?style=flat-square)
![Language](https://img.shields.io/badge/Language-Verilog-blue?style=flat-square)
![Python](https://img.shields.io/badge/Python-3.x-yellow?style=flat-square)

---

## 📋 프로젝트 개요

FPGA에서 OV7670 카메라부터 실시간 영상 처리, 피아노 인터페이스 및 필터 효과를 통합 구현한 하드웨어 기반 영상 시스템입니다.

### 🎯 주요 목표
- 화면 좌표와 타이머 기반 난수를 조절해 눈, 벚꽃, 바다속, 번개 필터 로직을 설계
- 좌표 스케일링을 적용해 필터의 위치, 이동 방향, 속도를 자연스럽게 제어
- 다중 필터 적용을 고려해 **레이어 우선순위와 조건 범위**를 분리해 구현

---

## ✨ 주요 기능

### 1. 영상 처리 & 필터 효과
- **VGA 에서 실시간 영상 처리 + 필터 오버레이**를 프레임 손실 없이 구현
- 발간색 객체 인식을 통해 손가락 좌표를 추출하고 이를 음계 인식에 활용
- **FPGA-PC 연동**을 통해 **손가락 음계 입력에 따른 음계 출력 및 필터 출력**이 지연 없이 동작

### 2. 피아노 인터페이스
- **발간색 객체 인식**을 통해 손가락 좌표를 추출하고 이를 음계 인식에 활용
- **FPGA-PC 연동**을 통해 **손가락 음계 입력에 따른 음계 출력 및 필터 출력**이 지연 없이 동작

### 3. 실시간 모드 전환
- **Pixel mode**: 255 샘플기 값 전송 → 복음 출력
- **Keyboard mode**: 건반 UART Data 전송 → 음계 출력

---

## 🏗️ 시스템 아키텍처

### 📊 Operation Mode
```
┌──────────────────┐        ┌──────────────────┐
│   Pixel Mode     │        │  Keyboard Mode   │
│                  │        │                  │
│   255 샘플기 값   │        │  건반 UART Data  │
│      전송        │        │       전송        │
│       ↓          │        │       ↓          │
│    묵음 출력      │        │   음계 출력      │
└──────────────────┘        └──────────────────┘
         │                           │
         └──────────┬────────────────┘
                    ▼
            Sampling Data 전송
                    │
                    ▼
                음계 출력
```

### 📊 Top BlockDiagram
![Block Diagram](./images/top_blockdiagram.jpg)

### 📊 화면 출력 (총 8개 Filter - snow Filter)
![Filter Piano_snow](./images/snowski.jpg)
![Filter Piano_spring](./images/cherryblossom.jpg)

---

## 🔧 개발 환경

|        항목       | 사양 |
|-------------------|------|
|    **Language**   | Verilog, Python |
|      **Tool**     | Vivado |
|      **FPGA**     | Basys3 (Xilinx) |
|     **Camera**    | OV7670 (VGA 640x480) |
| **Communication** | I2C, UART |
|     **Filter**    | Snow, Cherry Blossom, Underwater, Lightning, etc. (8 filters) |

---

## 📈 성능 지표

### ✅ 검증 결과
- **VGA 에서 실시간 영상 처리 + 필터 오버레이**를 프레임 손실 없이 구현
- 발간색 객체 인식을 통해 손가락 좌표를 추출하고 이를 음계 인식에 활용
- **FPGA-PC 연동**을 통해 **손가락 음계 입력에 따른 음계 출력 및 필터 출력**이 지연 없이 동작

### 🐛 Trouble Shooting

#### 1. 문제: UART TX 데이터 **연속 송신**으로 음계가 지속 출력되는 문제 발생
- **해결**: **Delay 모듈과 FIFO 구조**를 추가해 송신 주기를 제어하여 문제 해결

#### 2. 문제: 좌표 이동 중 **음계 오동작** 문제 발생(연속 필수)
- **해결**: **PC 키보드 트리거 방식**으로 개선

---

## 📁 프로젝트 구조

```
Filter-Piano/
├── rtl/                    # RTL 소스 코드
│   ├── ov7670_capture.v   # 카메라 캡처
│   ├── vga_controller.v   # VGA 출력
│   ├── filter_snow.v      # 눈 필터
│   ├── filter_cherry.v    # 벚꽃 필터
│   ├── color_detect.v     # 색상 인식
│   └── top.v
├── python/                 # Python 음계 출력
│   └── piano_sound.py
├── images/                 # 문서용 이미지
└── README.md
```

---

## 🚀 사용 방법

### 1. FPGA 합성 및 다운로드
```tcl
# Vivado에서
source build.tcl
program_hw_devices
```

### 2. Python 음계 출력 실행
```bash
# Python 환경 설정
pip install pyserial pygame

# 실행
python piano_sound.py
```

### 3. 피아노 연주
- **Pixel Mode**: 손가락을 카메라에 비추고 건반 위치에 맞춰 움직이기
- **Keyboard Mode**: PC 키보드로 직접 연주

---

## 🎨 Filter 종류

| Filter | 설명 | 효과 |
|--------|------|------|
| **Snow** | 눈 내리는 효과 | 위에서 아래로 떨어지는 하얀 눈송이, 스키타는 펭귄 |
| **Cherry Blossom** | 벚꽃 흩날리는 효과 | 분홍색 벚꽃잎이 바람에 날림 |
| **Underwater** | 물속 효과 | 푸른색 물결과 거품 |
| **Lightning** | 번개 효과 | 번쩍이는 번개 |
| ... | ... | ... |

**총 8개 필터 구현**

---

## 📚 참고 자료

- [OV7670 Datasheet](https://www.voti.nl/docs/OV7670.pdf)
- [VGA Signal Timing](http://tinyvga.com/vga-timing)
- [I2C Protocol](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)

---

## 👤 Author

**이서영 (Lee Seoyoung)**
- 📧 Email: lsy1922@naver.com
- 🔗 GitHub: [@seoY0206](https://github.com/seoY0206)

---

## 📝 License

This project is for educational purposes.

---

<div align="center">

**⭐ 도움이 되었다면 Star를 눌러주세요! ⭐**

</div>
