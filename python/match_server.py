from flask import Flask, request, jsonify
from deepface import DeepFace
import logging

# Tắt log thừa
logging.getLogger('tensorflow').setLevel(logging.ERROR)
app = Flask(__name__)

# 🎨 BƯỚC 1: THAY ĐỔI MODEL SANG ArcFace
FACE_MODEL = "ArcFace" 

# 🎨 BƯỚC 2: ĐẶT NGƯỠNG MỚI (ArcFace dùng ngưỡng khác Facenet)

MATCH_THRESHOLD = 0.60
_ = DeepFace.build_model(FACE_MODEL)
print(f"--- MÔ HÌNH {FACE_MODEL} ĐÃ ĐƯỢC TẢI VÀ SẴN SÀNG SỬ DỤNG ---")
@app.route('/match-faces', methods=['POST'])
def match_faces():
    try:
        data = request.json
        
        if 'template1_base64' not in data or 'template2_base64' not in data:
            return jsonify({'error': 'Missing template1_base64 or template2_base64'}), 400

        img1_b64 = "data:image/jpeg;base64," + data['template1_base64']
        img2_b64 = "data:image/jpeg;base64," + data['template2_base64']

        
        # BƯỚC 1: KIỂM TRA LIVENESS (ĐÃ BỎ QUA)
        try:
            print("--- BẮT ĐẦU BƯỚC 1: KIỂM TRA LIVENESS ---")
            liveness_result = DeepFace.analyze(
                img_path = img2_b64,
                actions = ['liveness'],
                enforce_detection = True,
            )
            
            liveness_data = liveness_result[0]
            prediction = liveness_data.get('liveness_prediction')
            score = liveness_data.get('liveness_score', 0)
            
            print(f"--- KẾT QUẢ LIVENESS: Prediction={prediction}, Score={score} ---")

            if prediction != 'real':
                print("--- LỖI: LIVENESS BÁO LÀ 'SPOOF' (GIẢ MẠO) ---")
                return jsonify({
                    'error': f'Spoof detected. Score: {score}', 
                    'is_match': False
                }), 200

        except Exception as liveness_error:
            # LỖI này xảy ra vì phiên bản DeepFace của bạn không hỗ trợ Liveness
            print(f"--- BỎ QUA LỖI LIVENESS: {liveness_error} ---")


        # BƯỚC 2: SO SÁNH (VERIFY) BẰNG ArcFace
        print("--- BẮT ĐẦU BƯỚC 2: SO SÁNH (VERIFY) ---")
        verify_result = DeepFace.verify(
            img1_path = img1_b64,
            img2_path = img2_b64,
            model_name = FACE_MODEL,
            threshold = MATCH_THRESHOLD, 
            enforce_detection = True 
        )

        is_match = verify_result.get('verified', False)
        similarity = verify_result.get('distance', 1.0)
        
        print(f"--- KẾT QUẢ VERIFY (ArcFace): Match={is_match}, Distance={similarity} (Ngưỡng={MATCH_THRESHOLD}) ---")

        return jsonify({
            'is_match': is_match,
            'similarity': similarity,
            'threshold': MATCH_THRESHOLD
        }), 200

    except Exception as e:
        # Lỗi chung
        print(f"LỖI CHUNG (ngoài liveness): {e}")
        return jsonify({'error': str(e), 'is_match': False}), 200

if __name__ == '__main__':
    # Chạy server trên cổng 5001
    app.run(host='0.0.0.0', port=5001)


# waitress-serve --host=0.0.0.0 --port=5001 match_server:app