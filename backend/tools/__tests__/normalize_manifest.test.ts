const path = require('path');
const normalizeModule = require('../normalize_manifest');

const { normalize } = normalizeModule;

if (!normalize) {
  throw new Error('normalize function not exported from normalize_manifest');
}

test('happy path preserves specVersion and endpoints', () => {
  const input = {
    specVersion: 'v1alpha1',
    projectId: 'myproj',
    endpoints: {
      api: { entryPoint: 'api', platform: 'gcfv2', region: ['us-central1'] }
    }
  };
  const out = normalize(input);
  expect(out.specVersion).toBe('v1alpha1');
  expect(out.projectId).toBe('myproj');
  expect(out.endpoints.api.entryPoint).toBe('api');
});

test('converts BigInt and undefined to safe values', () => {
  const input: any = {
    endpoints: {
      foo: { value: BigInt(123), maybe: undefined, arr: [1, BigInt(2), undefined, {x: BigInt(3)}] }
    }
  };
  const out = normalize(input);
  expect(out.endpoints.foo.value).toBe('123');
  expect(out.endpoints.foo.maybe).toBeNull();
  expect(Array.isArray(out.endpoints.foo.arr)).toBe(true);
  expect(out.endpoints.foo.arr[1]).toBe('2');
  expect(out.endpoints.foo.arr[2]).toBeNull();
  expect(out.endpoints.foo.arr[3].x).toBe('3');
});

test('non-finite numbers are stringified', () => {
  const input = { endpoints: { num: { v: Infinity } } };
  const out = normalize(input);
  expect(out.endpoints.num.v).toBe('Infinity');
});
