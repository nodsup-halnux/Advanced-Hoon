## Advanced Cores:

### Glossary:

- code-as-data: Recall: `[battery [sample context]]` or `[battery payload]`
- context: Exposed namespace, but for our purposes its the Payload Tail.
- sample: (our effective input), for gates (practically speaking)...
- Subtype: a datatype, related to another datatype via the notion of substitutability. Wherever the supertype is used, the subtype can typically be used. We can represent this with an ordering relation $\leq$. 
- Polymorphism: A programming paradigm that allows us to build code that uses different types at different times, during the compilation/run-time lifecycle.
- complex-type: a type formed from a union of more primitive language types, thorugh a struct, object, cell, etc.
- subtyping-relation: Define $S \leq T$ (S is a subset of T) to mean:  Any term of type S can be safely substituted in a context of type T.
    - Example:  \<duck\> $\leq$ \<bird\> $\leq$ \<organism\>. If we have a function that returns True on "Is a bird?", inputting duck will return True.
- Type Error: When a piece of code recieves a piece of data of a type it was not prepared to handle (or expecting). Example: Passing a string to an add integers function. Type errors can cause serious run-time errors, but type analysis at compiler time can cut down subsets of these errors, leading to better running programs.
- Type Safety: Basically, we can use a type in a given context, without risking a type error.
- Liskov Substitution Principle/. Suppose S $\leq$ T. Then:
$S \leq T \rightarrow \forall x:T.p(x)\rightarrow \forall y: S.p(y)$

Basically, if S is a subtype of T, this implies that if we have a provable property for the supertype, such a property is also provable for the subtype.

- Metallic Core (Gold, Zinc...): When these are referenced, we are referring to cores with different variance relations imposed on them.
- Wet Gate: A gate tha relies on Generality.
- Dry Gate: Our "standard" gate we learned in Basic Hoon. This can be extended with variance relations.


**There are also two main ideas to this lesson:**

(1) Variance: How subtypes between complex types relate to subtypes between components, or more basic types. More formal definition follows:

Let A, B be types, let $\leq$ be a type ordering relation. If $\mathbb{I}$ is a type constructure (read: a more complex entitiy), then define the following relations:

- Covariance: if $A \leq B$ then $\mathbb{I}$ [A] $\leq$ $\mathbb{I}$ [B]
- Contravariance: if $A \leq B$ then $\mathbb{I}$ [B] $\leq$ $\mathbb{I}$ [A]
- Bivariance: if $A \leq B$ then $\mathbb{I}$ [A] $\equiv$ $\mathbb{I}$ [B]
- Variant: if $A \leq B$ then co/con/bi-variance.
- Invariant: not Variant. So any other case where our relations just don't hold.



(2) Parametric Polymorphism (Generality):  Write functions/data-types in a way to operate on values of any type, without losing type safety.

- Example: A function that reverses a list exhibits Generality. The list item types don't matter at all, as the function just moves them around without inspecting them - no type inference needed.

Practically speaking, Parametric Polymorphism gives us flexibility of type for our gate. Variance defines sets of rules for gates to evaluate.

- **(!! Remember !!)**
    - **Parametric Polymorphism gives us Wet Gate Polymorphism**
    - **Variance Relations gives us Dry Gate Polymorphism**
### Wet v.s Dry Gates:

For elementary Hoon, we are exposed to the dry gate without even knowing it. This involves using a bar-cen (|%) core, or for most small programming problems, the gate definition (|=) (which is equivalent to a =+, |% with a $ arm).

For a **Dry Gate**, the following three things happen: 

(1) Compile the body into a Nock Formula. 
(2) Compile the sample into a Nock Formula, 
(3) Form a composite [formula payload subject] Nock Formula, which is dropped into a call site.  

**Main Idea:** Dry Gates are only compiled once. All we do is replace the sample, and drop the formula in place where it is required (recall: Hoon is pass-by-value)

One problem with Dry Gates, is that the type of our sample (when specified in the definition) is fixed. Whatever input we give the gate, the input must nest in the original sample type. Even if it nests, we may get unintented consequences when processing an input. Consider the following:

```
=ddouble |= (a=*  [a a])
::Run with an @ud
(ddouble 12)
>[12 12]
::Run with a @p
(ddouble ~nodsup-todsup)
>[167.564.993 167.564.993]

```
Our argument type is a supertype (any noun!). So our @ud and @p inputted also get upcast to this, and end up garbled on printing. But what if we just wanted to duplicate any type,  without it being cast as a noun? With wet gates, we can accomplish this!


#### The Wet Gate:

Wet gates are specified by the rune bar-tar (|*). This rune is equivalent to the following[1]:

```
|*  a=@ud
    (add a 2)

::Does the same thing, with more primative runes.
=|  a=@ud
|@
++  $  (add a 2)
```

Notice our bar-cen has been replaced by bar-pat (|@). This rune simply specifies that a wet core is to be defined.  By simply using these runes, our double gate example now works as expected:

```
=wdouble |*(a=* [a a])
::Run with an @ud
(wdouble 12)
>[12 12]
::Run with a @p
(wdouble ~nodsup-todsup)
>[~nodsup-todsup ~nodsup-todsup]
```

What happens when a wet-gate is compiled? Basically, instead of the formula body being compiled once, and some nesting type checking occuring for the sample input, this happens instead:

(1) Bunted sample is replaced by caller sample.
(2) Re-compile the formula into Nock using the new sample.
(3) Check if the old Nock Formula is the same as the new one.
(4)  If the same, just insert the newly compiled formula+sample into the call site. **Avoid the nesting check - wet gates don't consider this**

Some other facts about wet gates:
- if the sample does not alter the formula, the formula will always recompile to the same thing, irrespective of the type of input we provide.
- The nock formula (with sample) is *always* recompiled.
- No matter what types we pass, they are always preserved (not upcast or rejected, like with a Dry Gate)
    - Example of improper sample usage (from tislec[1]):

```
> =wet-gate-bad |*(f=@ud (f 3))
-find.$.+2
dojo: hoon expression failed
```

Here, we try to use an @ud as a gate call. Obviously, there is no $ arm to call.  The compiler does not know beforehand if this will work or not.

- Eventhough the compiler never checks the sample for the wet gate, we still need to be mindful of how the sample is used (as seen above).

**Why do we use wet gates?**  When the typing information isn't well characterized beforehand, or we deal with problems where typing just doesnt matter (such as our doubling cell problem, above)

### Making Parametric Polymorphic Strucutres:

The barbuc (|$) rune is used for this. This is how non-typed containers are are defined in hoon.hoon: For Example:

```
++  list
  |$  [item]
  ::    null-terminated list
  ::
  ::  mold generator: produces a mold of a null-terminated list of the
  ::  homogeneous type {a}.
  ::
  $@(~ [i=item t=(list item)])

```

### Metallic Cores:

- This is really about Dry Gate Polymorphism. It works by substituting cores.  
- Specifically: we care about passing cores as arguments to other gates, and the Variance Relations we impose on them.
- A core itself can be interpreted as a structured mold (indeed, code as data). How can we compare the shape of a core, and its internal types?
    -  "For core B to nest within core A, the batteries of A and B must 
        (i) have the same tree shape, and 
        (ii) the product of each B arm must nest within the product of the A arm."
    - We also apply a sample/payload test. This is where the "rules of variance" are applied and used.

- Key Ideas: 
    - Variance rules apply to the input and output of a core, not directly to the core itself.
    - *"You are able to use core-variance rules to create programs which take other programs as arguments"*
    - *"core variance ... since it impinges on how cores evaluate with other cores as inputs"*

- A summary table of the metallic cores is below:

| Metal: | Relation: | Wat? | Involves: | Pay Load: | Context: | Cast Rune: | PP Rep: | Other Notes: |
|---|---|---|---|---|---|---|---|---| 
| Gold | Invariant | Types mutually nest | Inputs and Outputs | Read and Write | Read and Write | NA |  [.](https://www.youtube.com/watch?v=ntG50eXbBtc)  |  Common everyday core. |
| Zinc | Covariance | Specific Type Nests in Generic Type | Output | Read Only | Opaque |  ^& | & |  A source. |
| Iron | Contravariance | Generic Type Nests in Specific Type | Input | Write Only | Opaque | \|~ | \| | A sink. |
| Lead | Bivariant |Both Relations (above) | ??? | Opaque | Opaque | \|? |  ?  |  Rarely used - for completeness. |

---

- Core terms of casting:  Gold $\rightarrow$ {Zinc, Iron} $\rightarrow$ Lead 
- Because Lead Cores don't have a payload or sample, |? creates a lead trap.
- *Opaquness means:* Not exported to namespace, and cannot read and write.
- Payload address: +6.z (recall this is sample and context!)
- Context (Tail) Address: +7.z

### Investigating in Depth:
#### Zinc Cores:

Lets go through the rules above, to see why the Generic and Variant Cores Examples actually work. First consider the casting of Zinc Cores:

```
:: In this first example, the shape of our core type is a buc arm that returns a 
:: constant (@), and takes a sample that is any cell. Our input core is the same.
> ^+(^&(|=(^ 15)) |=(^ 16))
< 1&jcu  ...

::  Here, our core to be cast has a sample type that is a subset of our
::  cast type, so it goes through (Covariance)
> ^+(^&(|=(^ 15)) |=([@ @] 16))
< 1&jcu  ...
>
:: When we try to provide a core with a sample that is a supertype (noun), 
:: we fail.
> ^+(^&(|=(^ 15)) |=(* 16))
nest-fail
```

So our covariance rule applies to the shape of the cores, and casting itself.

What happens when we probe a zinc core?

```
=zinc-gate ^&  |=(a=_22 (add 10 a))

::Can't make a function call!
> (zinc-gate 12)
payload-block

::Read Sample OK
> a.zinc-gate
22

::Run $ arm OK
> $.zinc-gate
32

::...We can access the payload tail directly!
=zinc-gate ^& =>([g=22 h=44] |=(a=_22 15))
+7.zinc-gate
>[22 44]

:: But weirdly, the payload tail values
:: have there type info stripped (noun'ed)
=> =zg2 ([h=15] ^+(^|(|=(@ud 15)) |=(@ud 16)))
(add -.+7.zg2 1)
> nest-fail
```

*Why is it that the payload is blocked for our computation inside the core, and why is the sample read-only?*

Suppose we have a computation {X} that accepts a zinc-gates.  Now consider a new zinc-gate, that has the same shape as our input gate, a covariant relationship with our original gate. So its sample, and/or product of its arms are subtypes of the original gate (they all nest). We now use this new gate in our computation {X}. 

**So why make the sample read-only, and turn our gate into a sink?

Suppose that writing to the sample **was not blocked**, an unscrupulous user/computation {X} could write a non-nested sample at RT, and break type safety. We only know things are safe when we cast the gate, not when the gate is used later on. So to ensure safety, we make it a read-only sink.


#### Iron Cores:

Lets go through casting first. This is fairly trivial. If our input gate to our cast has a subset computation or sample type, it will fail. For completeness

```
:: Inputs the same type (cell), as is computation arm output type. No issues.
> ^+(^|(|=(^ 15)) |=(^ 16))
< 1|jcu  ...  >

:: More specific sample for input gate. Nope (not Contravariant).
> ^+(^|(|=(^ 15)) |=([@ @] 16))
> nest-fail

:: Less specific sample for input gate. OK
> ^+(^|(|=(^ 15)) |=(* 16))
<  1|jcu  ... >

::Another Test:  a less specific computational arm: Fails
> ^+(^|(|=(^ 15)) |=(* .~~3.14))
> nest-fail

```


Probing the gate, we get the following:

```
 =iron-gate ^|  =>([g=22 h=44 .] |=(a=@ (add a g)))

 :: Can run our Iron-gate as a function call OK
 (iron-gate 10)
 >32

::For our given context, we can't read anything:
g.iron-gate
> find error

::Nor can we read the sample
a.iron-gate
>find error

:: You can look at g and h, however the face and type information have been stripped away. 
:: They have been pushed further down the tree!
+14.iron-gate
> 22

> -:!>(+14.iron-gate)
#t/*

```
*Why is it that the payload is obscured for our computation, and why is the sample write-only?*

Again, consider a computation {X} that accepts iron-cores of a certain shape. Relative to our interface, we cast a specific iron-core that has a contravariant relationship - so the sample can be a super-type, and the return type of the computational arms can be a super-type.

**So why is the sample write-only?** Consider the fact that our sample is a super-type - and has a default value. It could be the case that this default value falls outside of the output scope of our computation {X}. So if we call our iron-gate with such a default value, we can produce an output that is completely outside our type nesting (consider {SuperSet} - {Subset} as our output). So we force computation {X} to write a type-safe value to the sample - by restricting read access. This way, {X} must know to put a type safe input in our iron-gate when used, helping to ensure a type-safe output.


#### Lead Cores:

Quickly:

```
> =lead-gate ^?  |=(a=_22 (add 10 a))

:: Can run the computation arm OK
> $.lead-gate
>32

:: Can't read the sample:
> a.lead-gate
> find error

:: Can't function call
>(lead-gate 5)
>payload-block

:: Can we see the payload tail? Yes, 
:: but no type info again.
=lead-gate ^? =>([g=22 h=44] |=(a=_22 15))
>+14.lead-gate
>22
```

As obtuse as Lead Cores appear, the reasons for the payload and context opacity follows from Variance Definitions: Lead Cores are Bivariant. So the reasons we had for Zinc and Iron cores having restricted payloads both apply, making the payload completely opaque (no read or write!)


### Outstanding Questions:

In (3) why do we compare the new formula to the old formula? Can it sometimes change, based on the input?

## References:

[1]: Example taken from timluc-miptev's [Wet Gate tutorial](https://blog.timlucmiptev.space/wetgates.html). Not my own!