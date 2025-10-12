<?php

namespace App\Services;

use Kreait\Firebase\Factory;

class FirebaseAuthService
{
    public function makeAuth()
    {
        $cred = config('services.firebase.credentials');
        return (new Factory())
            ->withServiceAccount($cred)
            ->createAuth();
    }

    /**
     * Tạo Firebase Custom Token cho 1 user
     * @param string $uid  UID sẽ dùng bên Firebase (nên ổn định, vd "laravel:<user_id>")
     * @param array $claims Custom claims (vd role, email, name)
     */
    public function createCustomToken(string $uid, array $claims = []): string
    {
        $auth = $this->makeAuth();
        return $auth->createCustomToken($uid, $claims)->toString();
    }
}
