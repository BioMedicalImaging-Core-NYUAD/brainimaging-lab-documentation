#######################################
Brain Imaging: NYUAD documentation page
#######################################

.. figure:: /_static/mri_scanner.png
   :alt: MRI scanner image
   :width: 1200px
   :align: center

.. raw:: html

 <br><br>

   The Brain Imaging NYUAD lab, part of the BioMedical Imaging Core at NYU Abu Dhabi, provides a comprehensive documentation page covering the Magnetic Resonance Imaging (MRI) system and its associated ancillary equipment. This resource is aimed at all NYUAD users who need guidance on utilizing the lab's imaging facilities.


.. raw:: html

   <br><br>

****
Team
****

Osama Abdullah
---------------
.. image:: /_static/osama.jpg
   :width: 250px
   :align: left
   :alt: Osama Abdullah

**MRI Physicist II**

Osama is a research scientist and physicist who manages the daily operations of the BioMedical Imaging Core
at New York University Abu Dhabi, overseeing a research-dedicated 3-Tesla Siemens MRI scanner,
the MEG lab, and the Small Animal Imaging lab on campus.
In his role, he supports research activities and advances technical capabilities by
supervising researchers and technical staff and providing scientific assistance.

`osama.abdullah@nyu.edu <mailto:osama.abdullah@nyu.edu>`_

.. raw:: html

   <div style="clear: both;"></div>


Haidee Paterson
---------------
.. image:: /_static/haidee.jpg
   :width: 250px
   :align: left
   :alt: Haidee Paterson

**MRI Instrumentation Specialist**

Haidee is an MRI radiographer with 25 years of experience, primarily in clinical MRI practice.
Over the past 7 years, she has specialized as a research instrumentation specialist,
leveraging her extensive experience to advance MRI research.
Her focus is on supporting research projects in three distinct areas:
MRI data acquisition, MRI integrated with EEG, and MEG data acquisition.

`haidee.paterson@nyu.edu <mailto:haidee.paterson@nyu.edu>`_

.. raw:: html

   <div style="clear: both;"></div>



Lab Address
-----------

.. admonition:: Lab Address

   📍 **Brain Imaging Research Lab**
   A2, 014-015, Ground Floor,
   New York University,
   Abu Dhabi, Saadiyat Island




.. *********************
.. Documentation content
.. *********************

.. toctree::
    :hidden:
    :caption: Lab Overview
    :maxdepth: 2

    1-lab-overview/0-brainimaging-lab-description.rst
    1-lab-overview/1-brainimaging-policies.rst
    1-lab-overview/2-brainimaging-processes.rst
    1-lab-overview/3-brainimaging-publications.rst
    1-lab-overview/4-brainimaging-collaborations.rst
    1-lab-overview/6-brainimaging-contribution.rst


.. toctree::
    :hidden:
    :caption: MRI System
    :maxdepth: 2

    2-mri-scanner-system/1-technology-overview.rst
    2-mri-scanner-system/2-system-specification.rst



.. toctree::
    :hidden:
    :caption: EEG-fMRI System
    :maxdepth: 2


    3-eeg-fmri-system/2-system-specification.rst
    3-eeg-fmri-system/4-operational-protocol.rst
    3-eeg-fmri-system/5-experiment-design.rst


.. toctree::
   :hidden:
   :caption: MR spectroscopy
   :maxdepth: 2

   4-spectroscopy/introduction
   4-spectroscopy/pipeline/data_acquisition
   4-spectroscopy/pipeline/basis_file
   4-spectroscopy/pipeline/lcmodel_control
   4-spectroscopy/pipeline/notes
   4-spectroscopy/manuals/index.rst
   4-spectroscopy/manuals/lcmodel_manual.rst


.. toctree::
   :hidden:
   :caption: Experiments Gallery
   :maxdepth: 2

   5-mri-experiments-gallery/1-mri-experiments

.. toctree::
   :hidden:
   :caption: Data Gallery
   :maxdepth: 2

   6-mri-data-gallery/1-data-use-cases.rst

.. toctree::
   :hidden:
   :caption: Pipeline Gallery
   :maxdepth: 2

   7-mri-pipeline-gallery/1-mri-pipeline-overview
   7-mri-pipeline-gallery/2-mri-pipeline-gallery



.. toctree::
   :hidden:
   :caption: Beyond 2D
   :maxdepth: 2

   9-3D/Heart/Heart.rst
   9-3D/Spine/Spine.rst


.. raw:: html

   <div id="container3D" style="width:100%; height:600px; position:relative;">
       <div id="loading" style="position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); color:#666; font-size:18px;">Loading 3D Brain Model...</div>
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
           60, // a bit tighter FOV helps fitting
           container.clientWidth / container.clientHeight,
           0.01,
           2000
       );

       let object;
       let controls;

       const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
       renderer.setPixelRatio(window.devicePixelRatio); // NEW: crisp rendering
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

       // Utility: fit camera to an object using its bounding sphere
       function fitCameraToObject(object, camera, controls, padding = 1.1) { // NEW: helper
           const box = new THREE.Box3().setFromObject(object);
           const sphere = box.getBoundingSphere(new THREE.Sphere());

           // If the model has zero size, bail
           if (!isFinite(sphere.radius) || sphere.radius === 0) return;

           // Center the model at origin so rotation is natural
           object.position.sub(sphere.center);

           // After moving the object, recompute center/radius
           const box2 = new THREE.Box3().setFromObject(object);
           const sphere2 = box2.getBoundingSphere(new THREE.Sphere());

           // Put camera back on a consistent axis and distance
           const fov = THREE.MathUtils.degToRad(camera.fov);
           const distance = (sphere2.radius * padding) / Math.sin(fov / 2);

           camera.position.set(0, 0, distance); // look straight on
           camera.near = Math.max(0.01, distance / 1000);
           camera.far = distance * 1000;
           camera.updateProjectionMatrix();

           // Lock the controls target at the true center (origin after reposition)
           controls.target.set(0, 0, 0);
           controls.update();

           // Sensible zoom limits relative to model size
           controls.minDistance = sphere2.radius * 0.8;  // can’t get *inside* the brain
           controls.maxDistance = sphere2.radius * 10;   // can’t zoom out to oblivion

           // Optional: limit vertical tilt so users don’t flip under the model
           controls.minPolarAngle = 0.05;
           controls.maxPolarAngle = Math.PI - 0.05;

           // Store for runtime clamping
           controls.__minD = controls.minDistance;
           controls.__maxD = controls.maxDistance;
       }

       loader.load(
           '_static/model.glb',
           function (gltf) {
               console.log('Model loaded successfully!');
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

               // Scale to a consistent size (approx. 4 units max dim)
               const box = new THREE.Box3().setFromObject(object);
               const size = box.getSize(new THREE.Vector3());
               const maxDim = Math.max(size.x, size.y, size.z) || 1;
               object.scale.setScalar(4 / maxDim);

               scene.add(object);
               loading.style.display = 'none';

               // Now that the model exists, initialize controls & fit
               controls = new OrbitControls(camera, renderer.domElement);
               controls.enableDamping = true;
               controls.dampingFactor = 0.05;
               controls.enablePan = false;       // can’t shift target
               controls.enableRotate = true;
               controls.enableZoom = true;
               controls.rotateSpeed = 0.9;
               controls.zoomSpeed = 0.8;

               // Keep target pinned forever (safety net)
               controls.addEventListener('change', () => { // NEW: hard-lock target
                   controls.target.set(0, 0, 0);
               });

               // Fit once model is ready
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
               loading.innerHTML = '<div style="color:#ff6b6b;">Error loading model. Check console for details.</div>';
               console.error('Error loading model:', error);
           }
       );

       function animate() {
           requestAnimationFrame(animate);

           // NEW: distance clamp every frame — you’ll never lose the model
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

       // Handle container resizes robustly
       function onResize() {
           const w = container.clientWidth;
           const h = container.clientHeight;
           camera.aspect = w / h;
           camera.updateProjectionMatrix();
           renderer.setSize(w, h);
       }
       window.addEventListener("resize", onResize);

       // Optional: better resize handling when container size (not window) changes
       // (comment out if not needed on RTD)
       const ro = new ResizeObserver(onResize); // NEW
       ro.observe(container);

       animate();
   </script>

