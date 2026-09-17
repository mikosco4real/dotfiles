# Clean-machine test for the bootstrap.
#
# Deliberately starts from a bare ubuntu:24.04 with no sudo, no curl and no git,
# because that is what a fresh box actually looks like — and it is the only way
# to prove run_once_before_00-bootstrap-pkg-manager does its job.
#
# Built and driven by test/run.sh, which runs the bootstrap TWICE to prove
# idempotency.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    CI=true \
    LANG=C.UTF-8

# Minimal images have no sudo. The scripts detect uid 0 and skip sudo, but
# install it anyway so the non-root path is exercised too.
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
      sudo ca-certificates curl file git locales procps build-essential \
    && rm -rf /var/lib/apt/lists/*

# Non-root user with passwordless sudo — the realistic case, and it catches
# permission bugs that running as root would hide.
RUN useradd -m -s /bin/bash tester \
    && echo 'tester ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester

# Install chezmoi the same way the README tells a human to.
RUN sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin

USER tester
WORKDIR /home/tester

# The repo is mounted read-only at /dotfiles by run.sh and copied in, so the test
# can never write back to the working tree.
CMD ["/bin/bash"]
