# matrix

# MTX (Matrix)

MTX is an AI-native interpreted programming language built in C++.

It is designed to make local AI workflows like chatbots, image generation, agents, pipelines, and automation feel as simple as writing Python — but with a runtime built specifically for AI from the ground up.

## Features

* Native C++ interpreter/runtime
* Built-in AI functions (`ask`, `listen`, `train`)
* Chatbot and agent primitives
* ComfyUI image/video generation
* Local Ollama integration
* AI pipelines and automation workflows
* MatrixBase experimental database system
* Simple readable syntax
* Interactive REPL (`mtx`)
* Windows-first AI-native runtime

## Core Keywords

```mtx
let
fn
emit
if
else
for
in
while
safe
load
struct
ask
listen
train
watch
pipeline
agent
chatbot
generate_image
generate_video
show_image
```

## Example

```mtx
let image = generate_image("futuristic city at night, neon lights")
emit image
show_image(image)
```

## AI Example

```mtx
let answer = ask("Explain MTX in one sentence")
emit answer
```

## Chatbot Example

```mtx
chatbot Assistant { let input = listen() let response = ask(input) emit response }
```

## Vision

MTX aims to become a modern AI-native language for:

* Local AI applications
* Chatbots and agents
* AI pipelines
* Dataset workflows
* Image/video generation
* Automation systems
* Experimental AI runtimes

Built with a native C++ engine for performance, flexibility, and full runtime control.
