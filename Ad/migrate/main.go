// Installation-only import of the WebView2 minigame save. PBZ never runs this tool.
package main

import (
	"encoding/binary"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"unicode/utf16"

	"github.com/syndtr/goleveldb/leveldb"
	"github.com/syndtr/goleveldb/leveldb/opt"
)

func migrate(dir string) error {
	for _, slot := range []string{"battle-0.json", "battle-1.json"} {
		if _, err := os.Stat(filepath.Join(dir, slot)); err == nil {
			return nil
		} else if !os.IsNotExist(err) {
			return err
		}
	}
	source := filepath.Join(dir, "Profile", "EBWebView", "Default", "Local Storage", "leveldb")
	if _, err := os.Stat(filepath.Join(source, "CURRENT")); os.IsNotExist(err) {
		return nil
	} else if err != nil {
		return err
	}
	db, err := leveldb.OpenFile(source, &opt.Options{ReadOnly: true, ErrorIfMissing: true})
	if err != nil {
		return err
	}
	defer db.Close()
	raw, err := db.Get([]byte("_https://adgame.pbz.invalid\x00\x01pozhen-endless-v1"), nil)
	if errors.Is(err, leveldb.ErrNotFound) {
		return nil
	}
	if err != nil {
		return err
	}
	if len(raw) < 2 {
		return errors.New("empty saved battle")
	}
	var data []byte
	switch raw[0] {
	case 1:
		chars := make([]rune, len(raw)-1)
		for i, b := range raw[1:] {
			chars[i] = rune(b)
		}
		data = []byte(string(chars))
	case 0:
		if len(raw)%2 != 1 {
			return errors.New("invalid UTF-16 value")
		}
		chars := make([]uint16, (len(raw)-1)/2)
		for i := range chars {
			chars[i] = binary.LittleEndian.Uint16(raw[1+2*i:])
		}
		data = []byte(string(utf16.Decode(chars)))
	default:
		return errors.New("unknown saved battle encoding")
	}
	var p struct {
		Version   int
		Seconds   float64
		Completed int
		World     struct {
			Cards   []json.RawMessage
			Weapons []int
		}
	}
	if err = json.Unmarshal(data, &p); err != nil {
		return err
	}
	if p.Version != 2 || p.Seconds < 0 || p.Seconds >= 30 || len(p.World.Cards) != 2 || len(p.World.Weapons) != 11 {
		return errors.New("invalid saved battle")
	}
	f, err := os.CreateTemp(dir, "battle-import-*.tmp")
	if err != nil {
		return err
	}
	defer os.Remove(f.Name())
	_, err = f.Write(data)
	if err == nil {
		err = f.Sync()
	}
	closeErr := f.Close()
	if err != nil {
		return err
	}
	if closeErr != nil {
		return closeErr
	}
	// Link only if the destination is still absent. The old profile is read-only.
	if err = os.Link(f.Name(), filepath.Join(dir, "battle-0.json")); err != nil {
		return err
	}
	fmt.Printf("Imported ADgame battle: %d completed, %.2f seconds in this segment.\n", p.Completed, p.Seconds)
	return nil
}
func main() {
	if len(os.Args) != 2 {
		os.Exit(2)
	}
	if err := migrate(os.Args[1]); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
