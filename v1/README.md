# nlox — Tree-Walk Interpreter

A Nim implementation of the Lox tree-walk interpreter from Part II of
[Crafting Interpreters](https://craftinginterpreters.com/) by Robert Nystrom.

## About

Rather than following the Java reference implementation directly, this port
translates the core ideas into Nim — replacing the visitor pattern with variant
objects and `case` dispatch, free procs instead of class methods, and Nim's
module system in place of Java's class hierarchy. The translation has tradeoffs;
it isn't a straightforward win in either direction. See
[translation-notes.md](translation-notes.md) for a detailed breakdown of the
decisions and where they diverged from the Java source.

## Usage

Build:

```bash
nim compile lox.nim
```

Run a script:

```bash
./lox script.lox
```

Run the REPL:

```bash
./lox
```

The REPL accepts both statements (terminated with `;`) and bare expressions.

## Extensions

A few features beyond the base book implementation:

- Multiline block comments (`/* ... */`)
- `break` statements in loops
- Anonymous functions / lambdas

## Experience
A Bit About the Process of Writing nlox/v1 (06/24/2026)
I started the tree-walk interpreter (nlox/v1) with a very loose grasp of Nim. I had only even learned of existence a week prior and had done a handful of coding problems after skimming the documentation for a few days. I hadn't (and still haven't) touched Java since 2020, and that was my second CS class I had ever taken. I followed step-by-step instructions to set up Eclipse, and the culmination of my work was implementing a calculator. (I would later implement a very simple and unsecure password manager, but this did little to bolster my understanding of anything other than foundational ideas of computer science and data structures).

You might ask: "Seth, why would you think you could translate a language you don't know into another language you just found out about?". I think it came down to 3 things: hubris, lack of care for my mental well-being, and faith that AI (in this Claude using Sonnet 4.6) would be able to fill in the gaps in translation and syntax so long as I understood the logic. While the first two remained true throughout the process, the third would prove to be wrong in a way that is reflected in the architecture of this Lox implementation.

I'll save the details (you can see the translation notes linked above if you're curious about the specifics), but overall, decisions were made without forethought that would have made the translation easier. Initially, I took those at face value, but quickly decided I should stop and began to look up if the "idiomatic Nim" it was giving me was really what the community agreed on. After many reddit posts, a few Stack Overflow posts, a few back and forths with Claude, and some soul-searching, I'm still not sure. I've also said the word "idiomatic" enough times that it's beginning to lose what little meaning it did have before this project. What I do know is that the interpreter works. Since I'm not shipping this as a product, I'm not as concerned about the patchwork nature of some of my solutions, or the sloppiness of some the structures and code choices. 

Considering this is my first full interpreter, I feel like I did okay. The code is relatively self-documenting, and I tried to include all translation decisions in the notes. I don't think anyone will even read this, let alone roast me for any design decisions, but still, I hope to improve my implementation in the VM interpreter, which should be easier to translate due to my knowledge of C and the fact that I don't have to work out which parts of the code in the book are just Java infrastructure. Hopefully after doing 2 interpreters I'll feel a bit more comfortable with the concepts and can move on to doing a small language that people actually use. Maybe I'll build out the VM more since my understanding is that it should be easier to build on.

If I were to summarize my main takeaways it would be:

1. Learn both languages before you try to translate one to the other
2. Just because you tell a model you want idiomatic solutions doesn't mean it will actually give you them
3. No one can agree on what is idiomatic; just make sure your code is readable
4. Implementing one interpreter doesn't make you a genius, it just makes you a nerd who implemented an interpreter