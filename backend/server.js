// Local server entrypoint for Express app
const { app } = require('./dist/index.js');

const PORT = process.env.PORT || 8080;

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Local Express server listening on http://0.0.0.0:${PORT}`);
});
