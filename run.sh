# PROJECT=libpcap
echo "PROJECT=$PROJECT"

# pushd ./data/${PROJECT}
# ./build.sh
# popd

#  the following command is sufficient to perform fuzzing
cargo run --bin fuzzer -- ${PROJECT} -c $(nproc) -r
# you can run this command to fuse the programs into a fuzz driver that can be fuzzed:
cargo run --bin harness -- ${PROJECT} fuse-fuzzer
# And, you can execute the fuzzers you fused:
cargo run --bin harness -- ${PROJECT} fuzzer-run

# After 24 hours execution(s), you should deduplicate the reported crashes by PromptFuzz:
cargo run --bin harness -- ${PROJECT} sanitize-crash
# Then, you can collect and verbose the code coverage of your fuzzers by:
cargo run --bin harness -- ${PROJECT} coverage collect
cargo run --bin harness -- ${PROJECT} coverage report
