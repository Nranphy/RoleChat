{{flutter_js}}
{{flutter_build_config}}
_flutter.loader.load({
  config: {canvasKitBaseUrl: 'canvaskit/'},
  onEntrypointLoaded: async function(initializer) {
    const runner = await initializer.initializeEngine();
    await runner.runApp();
    document.getElementById('boot-status')?.remove();
  }
});
