#[macro_use]
extern crate kg_display_derive;

mod num {
    include!(concat!(env!("OUT_DIR"), "/num.rs"));
}

use kg_diag::*;
use self::num::*;

fn main() {
    println!("Hello, world!");
    let mut lexer = NumLexer::new();
    let s = "12123231231";
    let mut r = MemByteReader::new(s.as_bytes());
    loop {
        let t = lexer.next_token(&mut r).unwrap();
        println!("{:?}", t);
        if t.term() == Term::End {
            break;
        }
    }
}