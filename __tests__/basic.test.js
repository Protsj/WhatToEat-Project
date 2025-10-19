describe('Site structure', () => {
  const fs = require('fs');

  test('index.html exists', () => {
    expect(fs.existsSync('index.html')).toBe(true);
  });
});
test('about.html exists', () => {
    expect(fs.existsSync('about.html')).toBe(true);
  });
