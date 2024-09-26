<body>
<h1>Text-to-Speech Conversion with Google Cloud Functions and Terraform</h1>
<p>This project demonstrates how to deploy a serverless application on Google Cloud Platform (GCP) using <strong>Google Cloud Functions (2nd gen)</strong> and <strong>Terraform</strong>. The application automatically converts text files uploaded to a Cloud Storage bucket into MP3 audio files using the <strong>Google Cloud Text-to-Speech API</strong>.</p>

<h2>Table of Contents</h2>
<ul>
    <li><a href="#overview">Overview</a></li>
    <li><a href="#architecture">Architecture</a></li>
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#setup-and-deployment">Setup and Deployment</a></li>
    <ul>
        <li><a href="#1-clone-the-repository">1. Clone the Repository</a></li>
        <li><a href="#2-configure-gcp-authentication">2. Configure GCP Authentication</a></li>
        <li><a href="#3-initialize-terraform">3. Initialize Terraform</a></li>
        <li><a href="#4-deploy-the-infrastructure">4. Deploy the Infrastructure</a></li>
    </ul>
    <li><a href="#usage">Usage</a></li>
    <ul>
        <li><a href="#1-upload-a-text-file">1. Upload a Text File</a></li>
        <li><a href="#2-verify-the-output">2. Verify the Output</a></li>
    </ul>
    <li><a href="#project-structure">Project Structure</a></li>
    <li><a href="#code-explanation">Code Explanation</a></li>
    <ul>
        <li><a href="#terraform-configuration-main-tf-and-variables-tf">Terraform Configuration (<code>main.tf</code> and <code>variables.tf</code>)</a></li>
    </ul>
    <li><a href="#security-considerations">Security Considerations</a></li>
    <li><a href="#cleanup">Cleanup</a></li>
    <li><a href="#troubleshooting">Troubleshooting</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
</ul>

<hr>

<h2 id="overview">Overview</h2>
<p>This project automates the deployment of a serverless function that converts text files into speech using Google's Text-to-Speech API. When a text file is uploaded to a specified Cloud Storage bucket, the Cloud Function is triggered, processes the text, and outputs an MP3 file back to the same bucket.</p>

<p><strong>Key Technologies:</strong></p>
<ul>
    <li><strong>Google Cloud Functions (2nd gen)</strong></li>
    <li><strong>Google Cloud Storage</strong></li>
    <li><strong>Google Cloud Text-to-Speech API</strong></li>
    <li><strong>Terraform</strong></li>
</ul>

<hr>

<h2 id="architecture">Architecture</h2>
<p><!-- You can include an architecture diagram here if available. --></p>
<ol>
    <li><strong>User uploads a text file</strong> to the designated Cloud Storage bucket.</li>
    <li><strong>Cloud Storage triggers the Cloud Function</strong> via Eventarc when a new object is finalized.</li>
    <li><strong>Cloud Function reads the text file</strong>, synthesizes speech using the Text-to-Speech API, and writes the MP3 output back to the Cloud Storage bucket.</li>
</ol>

<hr>

<h2 id="prerequisites">Prerequisites</h2>
<ul>
    <li><strong>Google Cloud Platform Account</strong> with billing enabled.</li>
    <li><strong>Google Cloud SDK</strong> installed and authenticated.</li>
    <li><strong>Terraform</strong> installed (version 1.0 or later).</li>
    <li><strong>Python 3.12</strong> (if you wish to modify or test the Cloud Function code locally).</li>
</ul>

<hr>

<h2 id="setup-and-deployment">Setup and Deployment</h2>

<h3 id="1-clone-the-repository">1. Clone the Repository</h3>
<pre><code>git clone https://github.com/your-username/your-repository-name.git
cd your-repository-name
</code></pre>

<h3 id="2-configure-gcp-authentication">2. Configure GCP Authentication</h3>
<p>Ensure you are authenticated with GCP and have set the correct project:</p>
<pre><code>gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
</code></pre>
<p>Replace <code>YOUR_PROJECT_ID</code> with your actual Google Cloud project ID.</p>

<h3 id="3-initialize-terraform">3. Initialize Terraform</h3>
<pre><code>terraform init
</code></pre>

<h3 id="4-deploy-the-infrastructure">4. Deploy the Infrastructure</h3>
<pre><code>terraform apply -var="project_id=YOUR_PROJECT_ID"
</code></pre>
<ul>
    <li>Review the plan and type <code>yes</code> to confirm.</li>
    <li>Note the output <code>bucket_name</code>, which you'll use in the next steps.</li>
</ul>

<hr>

<h2 id="usage">Usage</h2>

<h3 id="1-upload-a-text-file">1. Upload a Text File</h3>
<p>Upload a <code>.txt</code> file to the Cloud Storage bucket created by Terraform.</p>
<p>You can upload files via the GCP Console or using the <code>gsutil</code> command-line tool:</p>
<pre><code>gsutil cp path/to/your-file.txt gs://YOUR_BUCKET_NAME/
</code></pre>
<p>Replace <code>YOUR_BUCKET_NAME</code> with the name of your bucket (e.g., <code>cf-tts-abc123</code>).</p>

<h3 id="2-verify-the-output">2. Verify the Output</h3>
<p>After a few moments, the Cloud Function will process the text file and generate an MP3 file with the same name appended by <code>_output.mp3</code>.</p>
<p>Check the bucket for the new MP3 file:</p>
<pre><code>gsutil ls gs://YOUR_BUCKET_NAME/
</code></pre>

<hr>

<h2 id="project-structure">Project Structure</h2>
<pre><code>.
├── function/
│   ├── main.py
│   └── requirements.txt
├── main.tf
├── variables.tf
└── README.md
</code></pre>
<ul>
    <li><strong>function/</strong>: Contains the Cloud Function code.
        <ul>
            <li><strong>main.py</strong>: Python script that processes the text file and interacts with the Text-to-Speech API.</li>
            <li><strong>requirements.txt</strong>: Lists Python dependencies for the Cloud Function.</li>
        </ul>
    </li>
    <li><strong>main.tf</strong>: Terraform configuration file for resource provisioning.</li>
    <li><strong>variables.tf</strong>: Defines input variables for Terraform.</li>
    <li><strong>README.md</strong>: Project documentation (this file).</li>
</ul>

<hr>

<h2 id="code-explanation">Code Explanation</h2>

<h3 id="terraform-configuration-main-tf-and-variables-tf">Terraform Configuration (<code>main.tf</code> and <code>variables.tf</code>)</h3>

<h4><code>main.tf</code></h4>
<p>The <code>main.tf</code> file contains the Terraform configuration to set up the necessary resources:</p>
<ul>
    <li><strong>Providers and Resources</strong>: Sets up the Google provider and enables required APIs.</li>
    <li><strong>Storage Bucket</strong>: Creates a Cloud Storage bucket for input/output files.</li>
    <li><strong>Function Deployment</strong>: Packages and uploads the Cloud Function code.</li>
    <li><strong>IAM Roles</strong>: Assigns necessary permissions to service accounts and service agents.</li>
    <li><strong>Event Trigger</strong>: Configures the function to be triggered by Cloud Storage events via Eventarc.</li>
</ul>

<h4><code>variables.tf</code></h4>
<p>The <code>variables.tf</code> file defines input variables for the Terraform configuration:</p>
<pre><code>variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
}

variable "bucket_name" {
  description = "The base name of the Google Cloud Storage bucket. A random suffix will be added to ensure uniqueness."
  type        = string
  default     = "cf-tts"
}
</code></pre>

<hr>

<h2 id="security-considerations">Security Considerations</h2>
<ul>
    <li><strong>Service Account Permissions</strong>: The service account is granted the <code>roles/editor</code> role for simplicity. For production environments, it's recommended to grant the least privileges necessary.</li>
    <li><strong>IAM Roles</strong>: Be cautious with IAM role assignments. Avoid granting broad permissions where possible.</li>
    <li><strong>Sensitive Data</strong>: Ensure no sensitive information is hard-coded or exposed in logs.</li>
</ul>

<hr>

<h2 id="cleanup">Cleanup</h2>
<p>To avoid incurring charges on GCP, destroy the resources when they are no longer needed:</p>
<pre><code>terraform destroy -var="project_id=YOUR_PROJECT_ID"
</code></pre>
<p>Confirm the action by typing <code>yes</code> when prompted.</p>

<hr>

<h2 id="troubleshooting">Troubleshooting</h2>
<ul>
    <li><strong>Cloud Function Not Triggering</strong>: Ensure that the event trigger is correctly set up and that files are uploaded to the correct bucket.</li>
    <li><strong>Permission Errors</strong>: Verify that all IAM roles are correctly assigned and that the service accounts have the necessary permissions.</li>
    <li><strong>API Not Enabled</strong>: If you encounter errors about APIs not being enabled, double-check that all required services are enabled in your GCP project.</li>
</ul>

<hr>

<h2 id="license">License</h2>
<p>This project is licensed under the <a href="LICENSE">MIT License</a>.</p>

<hr>

<h2 id="acknowledgments">Acknowledgments</h2>
<ul>
    <li><strong>Google Cloud Documentation</strong>:
        <ul>
            <li><a href="https://cloud.google.com/functions/docs">Cloud Functions</a></li>
            <li><a href="https://cloud.google.com/text-to-speech/docs">Text-to-Speech API</a></li>
        </ul>
    </li>
    <li><strong>Terraform</strong>:
        <ul>
            <li><a href="https://registry.terraform.io/providers/hashicorp/google/latest/docs">Terraform Google Provider</a></li>
        </ul>
    </li>
    <li><strong>Community Support</strong>: Thanks to the contributors and community forums for assistance.</li>
</ul>

<hr>

<p>Feel free to contribute to this project by opening issues or submitting pull requests. If you have any questions or need further assistance, please contact <a href="mailto:christian.lovstad@gmail.com">christian.lovstad@gmail.com</a>.</p>
</body>
