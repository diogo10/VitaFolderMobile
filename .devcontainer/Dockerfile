FROM dart

RUN apt-get update
RUN apt-get install -y curl git unzip xz-utils zip libglu1-mesa python3 python3-pip gh jq

RUN apt-get clean

# Install opencode
RUN curl -fsSL https://opencode.ai/v2/install | bash

# Install Flutter related dependencies
RUN git clone -b '3.41.6' --single-branch https://github.com/flutter/flutter.git --depth 1 /flutter
ENV PATH="/flutter/bin:$PATH"
RUN flutter doctor
RUN chmod 777 staff-setup.sh
