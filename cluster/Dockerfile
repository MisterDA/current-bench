FROM ocaml/opam:debian-ocaml-4.14 AS build
RUN sudo apt-get update && sudo apt-get install libc6-dev libev-dev capnproto m4 pkg-config libsqlite3-dev libgmp-dev libffi-dev -y --no-install-recommends
RUN opam remote add origin 'https://opam.ocaml.org' --all-switches && opam remote remove default && opam update
RUN sudo ln -f /usr/bin/opam-2.1 /usr/bin/opam
RUN opam install dune>=2.8 ppx_expect>=v0.14.1 prometheus ppx_sexp_conv dune-build-info lwt>=5.4.1 capnp-rpc-lwt>=1.2 capnp-rpc-net capnp-rpc-unix>=1.2 extunix>=0.3.2 logs conf-libev digestif>=0.8 fpath lwt-dllist prometheus-app=1.1 cohttp-lwt-unix sqlite3 psq mirage-crypto>=0.8.5 ppx_deriving ppx_deriving_yojson astring fmt>=0.8.9 cmdliner tar-unix>=2.0.0 yojson sexplib sha
RUN mkdir src && cd src && git clone --recurse-submodules 'https://github.com/ocurrent/ocluster'
WORKDIR src/ocluster
RUN opam pin -yn . --with-version=dev
RUN opam install -y --deps-only ./ocluster.opam
RUN opam exec -- dune build \
  ./_build/install/default/bin/ocluster-scheduler \
  ./_build/install/default/bin/ocluster-admin

FROM debian:stable-slim
RUN apt-get update && apt-get install libev4 libsqlite3-0 -y --no-install-recommends
RUN apt-get install ca-certificates -y  # https://github.com/mirage/ocaml-conduit/issues/388
WORKDIR /var/lib/ocluster-scheduler
ENTRYPOINT ["/usr/local/bin/ocluster-scheduler"]
COPY --from=build \
  /home/opam/src/ocluster/_build/install/default/bin/ocluster-scheduler \
  /home/opam/src/ocluster/_build/install/default/bin/ocluster-admin \
  /usr/local/bin/
