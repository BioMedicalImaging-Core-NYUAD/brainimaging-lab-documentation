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

*********************
Documentation content
*********************

.. toctree::
    :caption: Lab Overview
    :maxdepth: 2

    1-lab-overview/0-brainimaging-lab-description.rst
    1-lab-overview/1-brainimaging-policies.rst
    1-lab-overview/2-brainimaging-processes.rst
    1-lab-overview/3-brainimaging-publications.rst
    1-lab-overview/4-brainimaging-collaborations.rst
    1-lab-overview/5-brainimaging-useful-links.rst
    1-lab-overview/6-brainimaging-contribution.rst


.. toctree::
    :caption: MRI System
    :maxdepth: 2

    2-mri-scanner-system/1-technology-overview.rst
    2-mri-scanner-system/2-system-specification.rst
    2-mri-scanner-system/3-main-applications.rst
    2-mri-scanner-system/4-experiment-design.rst


.. toctree::
    :caption: EEG-fMRI System
    :maxdepth: 2

    3-eeg-fmri-system/1-technology-overview.rst
    3-eeg-fmri-system/2-system-specification.rst
    3-eeg-fmri-system/3-main-applications.rst
    3-eeg-fmri-system/4-operational-protocol.rst
    3-eeg-fmri-system/5-experiment-design.rst


.. toctree::
   :caption: MR spectroscopy
   :maxdepth: 2

   4-spectroscopy/introduction
   4-spectroscopy/pipeline/1-pipeline_overview
   4-spectroscopy/pipeline/data_acquisition
   4-spectroscopy/pipeline/basis_file
   4-spectroscopy/pipeline/organization
   4-spectroscopy/pipeline/lcmodel_control
   4-spectroscopy/pipeline/notes
   4-spectroscopy/manuals/index.rst
   4-spectroscopy/manuals/lcmodel_manual.rst


.. toctree::
   :caption: Experiments Gallery
   :maxdepth: 2

   5-mri-experiments-gallery/1-mri-experiments

.. toctree::
   :caption: Data Gallery
   :maxdepth: 2

   6-mri-data-gallery/1-data-use-cases.rst

.. toctree::
   :caption: Pipeline Gallery
   :maxdepth: 2

   7-mri-pipeline-gallery/1-mri-pipeline-overview
   7-mri-pipeline-gallery/2-mri-pipeline-gallery


.. toctree::
   :caption: Talks and demos
   :maxdepth: 2

   8-mri-talks-demos/1-talks-demos

.. raw:: html

   <div id="container3D" style="width:100%; height:600px; background:#1a1a2e; border-radius:8px; position:relative;">
       <div id="loading" style="position:absolute; top:50%; left:50%; transform:translate(-50%,-50%); color:white; font-size:18px;">Loading 3D Brain Model...</div>
   </div>
   
   <script type="module">
       //Import the THREE.js library
       import * as THREE from "https://cdn.skypack.dev/three@0.129.0/build/three.module.js";
       // To allow for the camera to move around the scene
       import { OrbitControls } from "https://cdn.skypack.dev/three@0.129.0/examples/jsm/controls/OrbitControls.js";
       // To allow for importing the .gltf file
       import { GLTFLoader } from "https://cdn.skypack.dev/three@0.129.0/examples/jsm/loaders/GLTFLoader.js";
       
       //Create a Three.JS Scene
       const scene = new THREE.Scene();
       scene.background = new THREE.Color(0x1a1a2e);
       
       //Get the container
       const container = document.getElementById("container3D");
       const loading = document.getElementById("loading");
       
       //create a new camera with positions and angles
       const camera = new THREE.PerspectiveCamera(
           75, 
           container.clientWidth / container.clientHeight, 
           0.1, 
           1000
       );
       
       //Keep the 3D object on a global variable so we can access it later
       let object;
       
       //OrbitControls allow the camera to move around the scene
       let controls;
       
       //Instantiate a loader for the .gltf file
       const loader = new GLTFLoader();
       
       // Try multiple paths
       const possiblePaths = [
           '_static/model.glb',
           '../_static/model.glb',
           './model.glb',
           'model.glb'
       ];
       
       let currentPathIndex = 0;
       
       function tryLoadModel() {
           if (currentPathIndex >= possiblePaths.length) {
               loading.innerHTML = '<div style="color:#ff6b6b;">Could not find model.glb. Check browser console (F12) for details.</div>';
               return;
           }
           
           const path = possiblePaths[currentPathIndex];
           console.log('Trying to load from:', path);
           loading.textContent = `Trying path ${currentPathIndex + 1}/${possiblePaths.length}...`;
           
           //Load the file
           loader.load(
               path,
               function (gltf) {
                   //If the file is loaded, add it to the scene
                   console.log('Model loaded successfully from:', path);
                   object = gltf.scene;
                   
                   // Optional: Change the material/color
                   object.traverse((child) => {
                       if (child.isMesh) {
                           child.material = new THREE.MeshPhongMaterial({ 
                               color: 0xff6b6b,
                               shininess: 100
                           });
                       }
                   });
                   
                   // Center and scale the model
                   const box = new THREE.Box3().setFromObject(object);
                   const center = box.getCenter(new THREE.Vector3());
                   object.position.sub(center);
                   
                   const size = box.getSize(new THREE.Vector3());
                   const maxDim = Math.max(size.x, size.y, size.z);
                   object.scale.setScalar(2 / maxDim);
                   
                   scene.add(object);
                   loading.style.display = 'none';
               },
               function (xhr) {
                   //While it is loading, log the progress
                   if (xhr.total > 0) {
                       const percent = Math.round((xhr.loaded / xhr.total * 100));
                       loading.textContent = `Loading: ${percent}%`;
                       console.log(percent + '% loaded');
                   }
               },
               function (error) {
                   //If there is an error, try next path
                   console.error('Failed to load from', path, ':', error);
                   currentPathIndex++;
                   tryLoadModel();
               }
           );
       }
       
       tryLoadModel();
       
       //Instantiate a new renderer and set its size
       const renderer = new THREE.WebGLRenderer({ antialias: true });
       renderer.setSize(container.clientWidth, container.clientHeight);
       
       //Add the renderer to the DOM
       container.appendChild(renderer.domElement);
       
       //Set how far the camera will be from the 3D model
       camera.position.set(3, 3, 5);
       
       //Add lights to the scene, so we can actually see the 3D model
       const topLight = new THREE.DirectionalLight(0xffffff, 1);
       topLight.position.set(500, 500, 500);
       topLight.castShadow = true;
       scene.add(topLight);
       
       const ambientLight = new THREE.AmbientLight(0xffffff, 0.5);
       scene.add(ambientLight);
       
       const backLight = new THREE.DirectionalLight(0xffffff, 0.5);
       backLight.position.set(-500, -500, -500);
       scene.add(backLight);
       
       //This adds controls to the camera, so we can rotate / zoom it with the mouse
       controls = new OrbitControls(camera, renderer.domElement);
       controls.enableDamping = true;
       controls.dampingFactor = 0.05;
       controls.enableZoom = true;
       
       //Render the scene
       function animate() {
           requestAnimationFrame(animate);
           
           // Update controls
           if (controls) controls.update();
           
           renderer.render(scene, camera);
       }
       
       //Add a listener to the window, so we can resize the window and the camera
       window.addEventListener("resize", function () {
           camera.aspect = container.clientWidth / container.clientHeight;
           camera.updateProjectionMatrix();
           renderer.setSize(container.clientWidth, container.clientHeight);
       });
       
       //Start the 3D rendering
       animate();
   </script>
