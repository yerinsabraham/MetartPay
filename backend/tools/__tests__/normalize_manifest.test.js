const path = require('path');
const normalizeModule = require('../normalize_manifest');

// normalize_manifest.js doesn't export functions currently; require it and pull normalize function by reading module.exports if available
let normalizeFn = null;
if (typeof normalizeModule.normalize === 'function') {
  normalizeFn = normalizeModule.normalize;
} else {
  // require the file and grab the function via eval hack: re-require as string
  const fs = require('fs');
  const code = fs.readFileSync(path.join(__dirname, '..', 'normalize_manifest.js'), 'utf8');
  // crude extraction: find "function normalize(manifest) {" and evaluate only that function
  const m = code.match(/function normalize\s*\(manifest\)\s*\{([\s\S]*?)^\}/m);
  if (m) {
    const fnBody = m[1];
    // eslint-disable-next-line no-new-func
    normalizeFn = new Function('manifest', fnBody);
  }
}

if (!normalizeFn) {
  throw new Error('Could not find normalize function in normalize_manifest.js');
}

test('happy path preserves specVersion and endpoints', () => {
  const input = {
    specVersion: 'v1alpha1',
    projectId: 'myproj',
    endpoints: {
      api: { entryPoint: 'api', platform: 'gcfv2', region: ['us-central1'] }
    }
  };
  const out = normalizeFn(input);
  expect(out.specVersion).toBe('v1alpha1');
  expect(out.projectId).toBe('myproj');
  expect(out.endpoints.api.entryPoint).toBe('api');
});

test('converts BigInt and undefined to safe values', () => {
  const input = {
    endpoints: {
      foo: { value: BigInt(123), maybe: undefined, arr: [1, BigInt(2), undefined, {x: BigInt(3)}] }
    }
  };
  const out = normalizeFn(input);
  expect(out.endpoints.foo.value).toBe('123');
  expect(out.endpoints.foo.maybe).toBeNull();
  expect(Array.isArray(out.endpoints.foo.arr)).toBe(true);
  expect(out.endpoints.foo.arr[1]).toBe('2');
  expect(out.endpoints.foo.arr[2]).toBeNull();
  expect(out.endpoints.foo.arr[3].x).toBe('3');
});

test('non-finite numbers are stringified', () => {
  const input = { endpoints: { num: { v: Infinity } } };
  const out = normalizeFn(input);
  expect(out.endpoints.num.v).toBe('Infinity');
});
