# Fix some issues in model to get the tests to run
sed -i 's/\.starts_with(/\.has_prefix(/g' model/yata_protocol.mbt
sed -i 's/\(tokens\|chunks\)\.length()/\1.count()/g' model/yata_protocol.mbt
sed -i 's/expected_entries > 0U && entries.length() != expected_entries/expected_entries > 0U && entries.count() != expected_entries/g' model/yata_protocol.mbt
sed -i 's/tokens[1]/tokens.get(1)/g' model/yata_protocol.mbt
sed -i 's/tokens[2]/tokens.get(2)/g' model/yata_protocol.mbt
sed -i 's/tokens[3]/tokens.get(3)/g' model/yata_protocol.mbt
sed -i 's/tokens[4]/tokens.get(4)/g' model/yata_protocol.mbt
sed -i 's/tokens[5]/tokens.get(5)/g' model/yata_protocol.mbt
sed -i 's/tokens[6]/tokens.get(6)/g' model/yata_protocol.mbt
sed -i 's/tokens[7]/tokens.get(7)/g' model/yata_protocol.mbt
sed -i 's/tokens[8]/tokens.get(8)/g' model/yata_protocol.mbt
sed -i 's/chunks[1]/chunks.get(1)/g' model/yata_protocol.mbt
