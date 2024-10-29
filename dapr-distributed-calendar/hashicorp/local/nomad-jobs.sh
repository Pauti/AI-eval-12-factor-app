#!/bin/bash

# Change directory to the jobs folder
cd ../nomad/jobs/

# Start all jobs
for job_file in *.hcl; do
    nomad job run "$job_file"
done
