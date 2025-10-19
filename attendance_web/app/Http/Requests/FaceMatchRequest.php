<?php


namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class FaceMatchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return (bool)$this->user(); // ai đăng nhập cũng có thể log match (GV kiosk hoặc SV tự điểm danh)
    }

    public function rules(): array
    {
        return [
            'attendance_session_id' => ['nullable', 'integer', 'exists:attendance_sessions,id'],
            'student_id' => ['nullable', 'integer', 'exists:students,id'],
            'face_template_id' => ['nullable', 'integer', 'exists:face_templates,id'],
            'method' => ['required', 'in:1:1,1:N'],
            'similarity' => ['required', 'numeric'],
            'threshold' => ['required', 'numeric'],
            'decision' => ['required', 'in:accept,reject'],
            'liveness_type' => ['nullable', 'in:none,passive,active'],
            'liveness_score' => ['nullable', 'numeric'],
            'spoof_flags' => ['nullable'],           // JSON string (client gửi)
            'model_version' => ['nullable', 'string', 'max:50'],
            'image_path' => ['nullable', 'string', 'max:255'],
        ];
    }
}

