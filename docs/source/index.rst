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

   <div id="stl-viewer" style="width:100%; height:600px; background:#1a1a2e; border-radius:8px;"></div>

   <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
   <script>
       // Scene setup
       const container = document.getElementById('stl-viewer');
       const scene = new THREE.Scene();
       scene.background = new THREE.Color(0x1a1a2e);

       const camera = new THREE.PerspectiveCamera(75, container.clientWidth / container.clientHeight, 0.1, 1000);
       const renderer = new THREE.WebGLRenderer({ antialias: true });
       renderer.setSize(container.clientWidth, container.clientHeight);
       container.appendChild(renderer.domElement);

       // Lighting
       const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
       scene.add(ambientLight);
       const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
       directionalLight.position.set(1, 1, 1);
       scene.add(directionalLight);

       // Load STL
       fetch('_static/new_rh_white.stl')
           .then(response => response.arrayBuffer())
           .then(buffer => {
               const geometry = parseSTLBinary(new DataView(buffer));
               geometry.computeVertexNormals();
               geometry.center();

               const material = new THREE.MeshPhongMaterial({ color: 0xff6b6b });
               const mesh = new THREE.Mesh(geometry, material);
               scene.add(mesh);

               // Auto-scale
               const box = new THREE.Box3().setFromObject(mesh);
               const size = box.getSize(new THREE.Vector3());
               const maxDim = Math.max(size.x, size.y, size.z);
               mesh.scale.setScalar(2 / maxDim);
           })
           .catch(err => console.error('Error loading STL:', err));

       function parseSTLBinary(view) {
           const faces = view.getUint32(80, true);
           const geometry = new THREE.BufferGeometry();
           const vertices = [];

           for (let i = 0; i < faces; i++) {
               const offset = 84 + i * 50;
               for (let j = 0; j < 3; j++) {
                   const vOffset = offset + 12 + j * 12;
                   vertices.push(
                       view.getFloat32(vOffset, true),
                       view.getFloat32(vOffset + 4, true),
                       view.getFloat32(vOffset + 8, true)
                   );
               }
           }

           geometry.setAttribute('position', new THREE.Float32BufferAttribute(vertices, 3));
           return geometry;
       }

       // Camera controls
       let rotation = { x: 0.3, y: 0 };
       container.addEventListener('mousemove', (e) => {
           if (e.buttons === 1) {
               rotation.y += e.movementX * 0.01;
               rotation.x += e.movementY * 0.01;
           }
       });

       camera.position.set(3, 3, 5);

       function animate() {
           requestAnimationFrame(animate);
           camera.position.x = 5 * Math.sin(rotation.y) * Math.cos(rotation.x);
           camera.position.y = 5 * Math.sin(rotation.x);
           camera.position.z = 5 * Math.cos(rotation.y) * Math.cos(rotation.x);
           camera.lookAt(0, 0, 0);
           renderer.render(scene, camera);
       }
       animate();
   </script>
