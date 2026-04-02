# Fix some issues in model to get the tests to run
sed -i 's/\.starts_with(/\.has_prefix(/g' model/yata_protocol.mbt
sed -i 's/\(tokens\|chunks\)\.length()/\1.count()/g' model/yata_protocol.mbt
