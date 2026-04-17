{{flutter_js}}
{{flutter_build_config}}

(function () {
  const serviceWorkerVersion = {{flutter_service_worker_version}};
  let reloadedForNewWorker = false;

  function promoteWorker(worker) {
    if (!worker) {
      return;
    }

    if (worker.state === "installed") {
      worker.postMessage("skipWaiting");
      return;
    }

    worker.addEventListener("statechange", function () {
      if (worker.state === "installed") {
        worker.postMessage("skipWaiting");
      }
    });
  }

  function enableFastServiceWorkerUpdates() {
    if (!serviceWorkerVersion || !("serviceWorker" in navigator)) {
      return;
    }

    navigator.serviceWorker.addEventListener("controllerchange", function () {
      if (reloadedForNewWorker) {
        return;
      }
      reloadedForNewWorker = true;
      window.location.reload();
    });

    navigator.serviceWorker
        .getRegistrations()
        .then(function (registrations) {
          for (const registration of registrations) {
            registration.addEventListener("updatefound", function () {
              promoteWorker(registration.installing);
            });

            promoteWorker(registration.waiting);
            promoteWorker(registration.installing);
            registration.update();
          }
        })
        .catch(function (error) {
          console.warn("Service worker refresh check failed.", error);
        });
  }

  enableFastServiceWorkerUpdates();

  _flutter.loader.load({
    serviceWorkerSettings: serviceWorkerVersion
        ? {
            serviceWorkerVersion: serviceWorkerVersion
          }
        : null
  });
})();
