/*
    Copyright 2017 Zheyong Fan, Ville Vierimaa, Mikko Ervasti, and Ari Harju
    This file is part of GPUMD.
    GPUMD is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    GPUMD is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with GPUMD.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma once

static __device__ __forceinline__ void find_fc(float rc, float rcinv, float d12, float& fc)
{
  if (d12 < rc) {
    float x = d12 * rcinv;
    fc = 0.5f * cos(3.1415927f * x) + 0.5f;
  } else {
    fc = 0.0f;
  }
}

static __device__ __forceinline__ void
find_fc_and_fcp(float rc, float rcinv, float d12, float& fc, float& fcp)
{
  if (d12 < rc) {
    float x = d12 * rcinv;
    fc = 0.5f * cos(3.1415927f * x) + 0.5f;
    fcp = -1.5707963f * sin(3.1415927f * x);
    fcp *= rcinv;
  } else {
    fc = 0.0f;
    fcp = 0.0f;
  }
}

static __device__ void
find_fn(const int n, const float rcinv, const float d12, const float fc12, float& fn)
{
  if (n == 0) {
    fn = fc12;
  } else if (n == 1) {
    float x = 2.0f * (d12 * rcinv - 1.0f) * (d12 * rcinv - 1.0f) - 1.0f;
    fn = (x + 1.0f) * 0.5f * fc12;
  } else {
    float x = 2.0f * (d12 * rcinv - 1.0f) * (d12 * rcinv - 1.0f) - 1.0f;
    float t0 = 1.0f;
    float t1 = x;
    float t2;
    for (int m = 2; m <= n; ++m) {
      t2 = 2.0f * x * t1 - t0;
      t0 = t1;
      t1 = t2;
    }
    fn = (t2 + 1.0f) * 0.5f * fc12;
  }
}

static __device__ void find_fn_and_fnp(
  const int n,
  const float rcinv,
  const float d12,
  const float fc12,
  const float fcp12,
  float& fn,
  float& fnp)
{
  if (n == 0) {
    fn = fc12;
    fnp = fcp12;
  } else if (n == 1) {
    float x = 2.0f * (d12 * rcinv - 1.0f) * (d12 * rcinv - 1.0f) - 1.0f;
    fn = (x + 1.0f) * 0.5f;
    fnp = 2.0f * (d12 * rcinv - 1.0f) * rcinv * fc12 + fn * fcp12;
    fn *= fc12;
  } else {
    float x = 2.0f * (d12 * rcinv - 1.0f) * (d12 * rcinv - 1.0f) - 1.0f;
    float t0 = 1.0f;
    float t1 = x;
    float t2;
    float u0 = 1.0f;
    float u1 = 2.0f * x;
    float u2;
    for (int m = 2; m <= n; ++m) {
      t2 = 2.0f * x * t1 - t0;
      t0 = t1;
      t1 = t2;
      u2 = 2.0f * x * u1 - u0;
      u0 = u1;
      u1 = u2;
    }
    fn = (t2 + 1.0f) * 0.5f;
    fnp = n * u0 * 2.0f * (d12 * rcinv - 1.0f) * rcinv;
    fnp = fnp * fc12 + fn * fcp12;
    fn *= fc12;
  }
}

static __device__ __forceinline__ void
find_fn(const int n_max, const float rcinv, const float d12, const float fc12, float* fn)
{
  float x = 2.0f * (d12 * rcinv - 1.0f) * (d12 * rcinv - 1.0f) - 1.0f;
  fn[0] = 1.0f;
  fn[1] = x;
  for (int m = 2; m <= n_max; ++m) {
    fn[m] = 2.0f * x * fn[m - 1] - fn[m - 2];
  }
  for (int m = 0; m <= n_max; ++m) {
    fn[m] = (fn[m] + 1.0f) * 0.5f * fc12;
  }
}

static __device__ __forceinline__ void find_fn_and_fnp(
  const int n_max,
  const float rcinv,
  const float d12,
  const float fc12,
  const float fcp12,
  float* fn,
  float* fnp)
{
  float x = 2.0f * (d12 * rcinv - 1.0f) * (d12 * rcinv - 1.0f) - 1.0f;
  fn[0] = 1.0f;
  fnp[0] = 0.0f;
  fn[1] = x;
  fnp[1] = 1.0f;
  float u0 = 1.0f;
  float u1 = 2.0f * x;
  float u2;
  for (int m = 2; m <= n_max; ++m) {
    fn[m] = 2.0f * x * fn[m - 1] - fn[m - 2];
    fnp[m] = m * u1;
    u2 = 2.0f * x * u1 - u0;
    u0 = u1;
    u1 = u2;
  }
  for (int m = 0; m <= n_max; ++m) {
    fn[m] = (fn[m] + 1.0f) * 0.5f;
    fnp[m] *= 2.0f * (d12 * rcinv - 1.0f) * rcinv;
    fnp[m] = fnp[m] * fc12 + fn[m] * fcp12;
    fn[m] *= fc12;
  }
}

static __device__ __forceinline__ void
find_poly_cos(const int L_max, const float x, float* poly_cos)
{
  poly_cos[0] = 0.079577471545948f;
  poly_cos[1] = 0.238732414637843f * x;
  float x2 = x * x;
  poly_cos[2] = 0.596831036594608f * x2 - 0.198943678864869f;
  float x3 = x2 * x;
  poly_cos[3] = 1.392605752054084f * x3 - 0.835563451232451f * x;
  float x4 = x3 * x;
  poly_cos[4] = 3.133362942121690f * x4 - 2.685739664675734f * x2 + 0.268573966467573f;
  float x5 = x4 * x;
  poly_cos[5] = 6.893398472667717f * x5 - 7.659331636297464f * x3 + 1.641285350635171f * x;
  float x6 = x5 * x;
  poly_cos[6] = 14.935696690780054f * x6 - 20.366859123790981f * x4 + 6.788953041263660f * x2 -
                0.323283478155412f;
}

static __device__ __forceinline__ void
find_poly_cos_and_der(const int L_max, const float x, float* poly_cos, float* poly_cos_der)
{
  poly_cos[0] = 0.079577471545948f;
  poly_cos[1] = 0.238732414637843f * x;
  poly_cos_der[0] = 0.0f;
  poly_cos_der[1] = 0.238732414637843f;
  poly_cos_der[2] = 1.193662073189215f * x;
  float x2 = x * x;
  poly_cos[2] = 0.596831036594608f * x2 - 0.198943678864869f;
  poly_cos_der[3] = 4.177817256162252f * x2 - 0.835563451232451f;
  float x3 = x2 * x;
  poly_cos[3] = 1.392605752054084f * x3 - 0.835563451232451f * x;
  poly_cos_der[4] = 12.533451768486758f * x3 - 5.371479329351468f * x;
  float x4 = x3 * x;
  poly_cos[4] = 3.133362942121690f * x4 - 2.685739664675734f * x2 + 0.268573966467573f;
  poly_cos_der[5] = 34.466992363338584f * x4 - 22.977994908892391f * x2 + 1.641285350635171f;
  float x5 = x4 * x;
  poly_cos[5] = 6.893398472667717f * x5 - 7.659331636297464f * x3 + 1.641285350635171f * x;
  poly_cos_der[6] = 89.614180144680319f * x5 - 81.467436495163923f * x3 + 13.577906082527321f * x;
  float x6 = x5 * x;
  poly_cos[6] = 14.935696690780054f * x6 - 20.366859123790981f * x4 + 6.788953041263660f * x2 -
                0.323283478155412f;
}

static __device__ __forceinline__ void get_f12_1(
  const float d12inv,
  const float fn,
  const float fnp,
  const float Fp,
  const float* s,
  const float* r12,
  float* f12)
{
  float tmp = s[1] * r12[0];
  tmp += s[2] * r12[1];
  tmp *= 2.0f;
  tmp += s[0] * r12[2];
  tmp *= Fp * fnp * d12inv;
  for (int d = 0; d < 3; ++d) {
    f12[d] += tmp * r12[d];
  }
  tmp = Fp * fn;
  f12[0] += tmp * 2.0f * s[1];
  f12[1] += tmp * 2.0f * s[2];
  f12[2] += tmp * s[0];
}

static __device__ __forceinline__ void get_f12_2(
  const float d12,
  const float d12inv,
  const float fn,
  const float fnp,
  const float Fp,
  const float* s,
  const float* r12,
  float* f12)
{
  float tmp = s[1] * r12[0] * r12[2];                // Re[Y21]
  tmp += s[2] * r12[1] * r12[2];                     // Im[Y21]
  tmp += s[3] * (r12[0] * r12[0] - r12[1] * r12[1]); // Re[Y22]
  tmp += s[4] * 2.0f * r12[0] * r12[1];              // Im[Y22]
  tmp *= 2.0f;
  tmp += s[0] * (3.0f * r12[2] * r12[2] - d12 * d12); // Y20
  tmp *= Fp * fnp * d12inv;
  for (int d = 0; d < 3; ++d) {
    f12[d] += tmp * r12[d];
  }
  tmp = Fp * fn * 2.0f;
  f12[0] += tmp * (-s[0] * r12[0] + s[1] * r12[2] + 2.0f * s[3] * r12[0] + 2.0f * s[4] * r12[1]);
  f12[1] += tmp * (-s[0] * r12[1] + s[2] * r12[2] - 2.0f * s[3] * r12[1] + 2.0f * s[4] * r12[0]);
  f12[2] += tmp * (2.0f * s[0] * r12[2] + s[1] * r12[0] + s[2] * r12[1]);
}

static __device__ __forceinline__ void get_f12_3(
  const float d12,
  const float d12inv,
  const float fn,
  const float fnp,
  const float Fp,
  const float* s,
  const float* r12,
  float* f12)
{
  float d12sq = d12 * d12;
  float x2 = r12[0] * r12[0];
  float y2 = r12[1] * r12[1];
  float z2 = r12[2] * r12[2];
  float xy = r12[0] * r12[1];
  float xz = r12[0] * r12[2];
  float yz = r12[1] * r12[2];

  float tmp = s[1] * (5.0f * z2 - d12sq) * r12[0];
  tmp += s[2] * (5.0f * z2 - d12sq) * r12[1];
  tmp += s[3] * (x2 - y2) * r12[2];
  tmp += s[4] * 2.0f * xy * r12[2];
  tmp += s[5] * r12[0] * (x2 - 3.0f * y2);
  tmp += s[6] * r12[1] * (3.0f * x2 - y2);
  tmp *= 2.0f;
  tmp += s[0] * (5.0f * z2 - 3.0f * d12sq) * r12[2];
  tmp *= Fp * fnp * d12inv;
  for (int d = 0; d < 3; ++d) {
    f12[d] += tmp * r12[d];
  }

  // x
  tmp = s[1] * (4.0f * z2 - 3.0f * x2 - y2);
  tmp += s[2] * (-2.0f * xy);
  tmp += s[3] * 2.0f * xz;
  tmp += s[4] * (2.0f * yz);
  tmp += s[5] * (3.0f * (x2 - y2));
  tmp += s[6] * (6.0f * xy);
  tmp *= 2.0f;
  tmp += s[0] * (-6.0f * xz);
  f12[0] += tmp * Fp * fn;
  // y
  tmp = s[1] * (-2.0f * xy);
  tmp += s[2] * (4.0f * z2 - 3.0f * y2 - x2);
  tmp += s[3] * (-2.0f * yz);
  tmp += s[4] * (2.0f * xz);
  tmp += s[5] * (-6.0f * xy);
  tmp += s[6] * (3.0f * (x2 - y2));
  tmp *= 2.0f;
  tmp += s[0] * (-6.0f * yz);
  f12[1] += tmp * Fp * fn;
  // z
  tmp = s[1] * (8.0f * xz);
  tmp += s[2] * (8.0f * yz);
  tmp += s[3] * (x2 - y2);
  tmp += s[4] * (2.0f * xy);
  tmp *= 2.0f;
  tmp += s[0] * (9.0f * z2 - 3.0f * d12sq);
  f12[2] += tmp * Fp * fn;
}
