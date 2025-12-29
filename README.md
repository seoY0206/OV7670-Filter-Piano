# OV7670-Filter-Piano
FPGA-based real-time video processing system that detects color objects from OV7670 camera input and maps screen coordinates to piano notes.

## ✨Overview
OV7670 카메라 입력 영상을 기반으로 특정 색상 객체를 실시간 인식하고,  
화면 좌표를 음계로 변환하여 피아노 연주 인터랙션을 구현한 FPGA 영상 처리 프로젝트입니다.

## ⚙️Tool & Language
- Verilog / SystemVerilog  
- FPGA (Basys3)  
- OV7670 Camera (VGA)  
- Python (UART 연동)  

## 🧱Architecture
- OV7670 VGA 영상 입력 및 타이밍 제어  
- RGB 기반 색상 필터 처리  
- 객체 영역 검출 및 화면 좌표 계산  
- 좌표 기반 음계 매핑 로직  
- FPGA–PC UART 통신 구조  

## 🪄Verification & Performance
- VGA 해상도에서 실시간 영상 처리 안정 동작 확인  
- 색상 필터 기반 객체 인식 정확도 확보  
- 좌표–음계 변환 지연 없는 인터랙션 구현  
- FPGA–Python UART 연동을 통한 음계 출력 정상 동작  

## 📍Key Features
- 빨간색 객체 인식 기반 음계 도출  
- 화면 좌표에 따른 피아노 음계 매핑  
- 실시간 영상 필터 처리 및 인터랙션 구현  
- FPGA와 소프트웨어 연동 경험 확보

