-----
Heart
-----
.. raw:: html

   <div id="container3D" style="width:100%; height:600px; position:relative;">
       <div id="loading" style="position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); color:#666; font-size:18px;">Loading 3D Heart Model...</div>
   </div>
   
   <script type="module">
       import * as THREE from "https://cdn.skypack.dev/three@0.129.0/build/three.module.js";
       import { OrbitControls } from "https://cdn.skypack.dev/three@0.129.0/examples/jsm/controls/OrbitControls.js";
       import { GLTFLoader } from "https://cdn.skypack.dev/three@0.129.0/examples/jsm/loaders/GLTFLoader.js";
       import { DRACOLoader } from "https://cdn.skypack.dev/three@0.129.0/examples/jsm/loaders/DRACOLoader.js";
       
       const scene = new THREE.Scene();
       scene.background = null;

       const container = document.getElementById("container3D");
       const loading = document.getElementById("loading");

       const camera = new THREE.PerspectiveCamera(
           60,
           container.clientWidth / container.clientHeight,
           0.01,
           2000
       );

       let object;
       let controls;

       const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
       renderer.setPixelRatio(window.devicePixelRatio);
       renderer.setSize(container.clientWidth, container.clientHeight);
       container.appendChild(renderer.domElement);

       const loader = new GLTFLoader();
       const dracoLoader = new DRACOLoader();
       dracoLoader.setDecoderPath('https://www.gstatic.com/draco/versioned/decoders/1.5.6/');
       dracoLoader.setDecoderConfig({ type: 'js' });
       loader.setDRACOLoader(dracoLoader);

       const topLight = new THREE.DirectionalLight(0xffffff, 1);
       topLight.position.set(500, 500, 500);
       topLight.castShadow = true;
       scene.add(topLight);

       const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
       scene.add(ambientLight);

       const backLight = new THREE.DirectionalLight(0xffffff, 0.5);
       backLight.position.set(-500, -500, -500);
       scene.add(backLight);

       function fitCameraToObject(object, camera, controls, padding = 1.1) {
           const box = new THREE.Box3().setFromObject(object);
           const sphere = box.getBoundingSphere(new THREE.Sphere());

           if (!isFinite(sphere.radius) || sphere.radius === 0) return;

           object.position.sub(sphere.center);

           const box2 = new THREE.Box3().setFromObject(object);
           const sphere2 = box2.getBoundingSphere(new THREE.Sphere());

           const fov = THREE.MathUtils.degToRad(camera.fov);
           const distance = (sphere2.radius * padding) / Math.sin(fov / 2);

           camera.position.set(0, 0, distance);
           camera.near = Math.max(0.01, distance / 1000);
           camera.far = distance * 1000;
           camera.updateProjectionMatrix();

           controls.target.set(0, 0, 0);
           controls.update();

           controls.minDistance = sphere2.radius * 0.8;
           controls.maxDistance = sphere2.radius * 10;

           controls.minPolarAngle = 0.05;
           controls.maxPolarAngle = Math.PI - 0.05;

           controls.__minD = controls.minDistance;
           controls.__maxD = controls.maxDistance;
       }

       loader.load(
           '../../_static/heart.glb',   // 🔴 FIXED PATH: go up 2 folders to reach _static
           function (gltf) {
               console.log('Heart model loaded successfully!');
               object = gltf.scene;

               object.traverse((child) => {
                   if (child.isMesh) {
                       child.material = new THREE.MeshPhongMaterial({ 
                           color: 0xff6b6b,
                           shininess: 100
                       });
                       child.castShadow = true;
                       child.receiveShadow = true;
                   }
               });

               const box = new THREE.Box3().setFromObject(object);
               const size = box.getSize(new THREE.Vector3());
               const maxDim = Math.max(size.x, size.y, size.z) || 1;
               object.scale.setScalar(4 / maxDim);

               scene.add(object);
               loading.style.display = 'none';

               controls = new OrbitControls(camera, renderer.domElement);
               controls.enableDamping = true;
               controls.dampingFactor = 0.05;
               controls.enablePan = false;
               controls.enableRotate = true;
               controls.enableZoom = true;
               controls.rotateSpeed = 0.9;
               controls.zoomSpeed = 0.8;

               controls.addEventListener('change', () => {
                   controls.target.set(0, 0, 0);
               });

               fitCameraToObject(object, camera, controls, 1.25);
           },
           function (xhr) {
               if (xhr.total > 0) {
                   const percent = Math.round((xhr.loaded / xhr.total * 100));
                   loading.textContent = `Loading: ${percent}%`;
                   console.log(percent + '% loaded');
               }
           },
           function (error) {
               loading.innerHTML = '<div style="color:#ff6b6b;">Error loading heart model. Check console for details.</div>';
               console.error('Error loading heart model:', error);
           }
       );

       function animate() {
           requestAnimationFrame(animate);

           if (controls) {
               const dist = camera.position.length();
               const minD = controls.__minD ?? 0.1;
               const maxD = controls.__maxD ?? 1000;
               if (dist < minD) camera.position.setLength(minD);
               if (dist > maxD) camera.position.setLength(maxD);
               controls.update();
           }

           renderer.render(scene, camera);
       }

       function onResize() {
           const w = container.clientWidth;
           const h = container.clientHeight;
           camera.aspect = w / h;
           camera.updateProjectionMatrix();
           renderer.setSize(w, h);
       }
       window.addEventListener("resize", onResize);

       const ro = new ResizeObserver(onResize);
       ro.observe(container);

       animate();
   </script>

