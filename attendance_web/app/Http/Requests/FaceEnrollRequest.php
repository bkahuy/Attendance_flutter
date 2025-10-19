<?php


namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class FaceEnrollRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'student'; // chỉ SV mới được enroll khuôn mặt của mình
    }

    public function rules(): array
    {
        return [
            'template_base64' => ['required', 'string'],
            'provider' => ['nullable', 'string'],
            'version' => ['required', 'string', 'max:50'],
            'quality_score' => ['nullable', 'numeric'],
            'is_primary' => ['sometimes', 'boolean'],
        ];
    }
}

