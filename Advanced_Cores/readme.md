## Advanced Cores:

### Glossary:

- code-as-data: Recall: `[battery [sample payload]]`
- Polymorphism: A programming paradigm that allows us to build code that uses different types at different times, during the compilation/run-time lifecycle.
- complex-type: a type formed from a union of more primitive language types, thorugh a struct, object, cell, etc.
- subtyping-relation: Define $S \leq T$ (S is a subset of T) to mean:  Any term of type S can be safely substituted in a context of type T.
    - Example:  \<duck\> $\leq$ \<bird\> $\leq$ \<organism\>

- Type Safety: Basically, we can use a type in a given context, without risking a run-time error.
- Liskov Substitution Principle/. Suppose S $\leq$ T. Then:
$S \leq T \rightarrow \forall x:T.p(x)\rightarrow \forall y: S.p(y)$

Basically, if S is a subtype of T, this implies that if we have a provable property for the supertype, such a property is also provable for the subtype.

- Metallic Core (Gold, Zinc...): When these are referenced, we are referring to cores with different variance relations imposed on them.
- Wet gate: A gate tha relies on generality.
- Dry Gate: Our "standard" gate we learned in Basic Hoon. This can be extended with variance relations.
There are also two main ideas to this lesson:

(1) Variance: How subtypes between complex types relate to subtypes between components, or more basic types. More formal definition follows:

Let A, B be types, let $\leq$ be a type ordering relation. If I is a type constructure (read: a more complex entitiy), then define the following relations:

- Covariance: if $A \leq B$ then I \<A\> $\leq$ I \<B\>
- Contravariance: if $A \leq B$ then I \<B\> $\leq$ I \<A\>
- Bivariance: if $A \leq B$ then I \<A\> $\equiv$ I \<B\>
- Variant: if $A \leq B$ then co/con/bi-variance.
- Invariant: not Variant. So any other case where our relations just don't hold.



(2) Parametric Polymorphism (Generality):  Write functions/data-types in a way to operate on values of any type, without losing type safety. Practically, an extra "Type" parameter is provided to the code construct, to aid with this.

- Example: A function that reverses a list. The list item types don't matter at all.

Practically speaking, Parametric Polymorphism gives us flexibility of type for our gate. Variance defintes sets of rules for gates to evaluate.
- **(!! Remember !!)**
    - **Parametric Polymorphism gives us Wet Gate Polymorphism**
    - **Variance Relations gives us Dry Gate Polymorphism**
### Wet v.s Dry Gates:

For elementary Hoon, we are exposed to the dry gate without even knowing it. This involves using a bar-cen (|%) core, or for most small programming problems, the gate definition (|=) (which is equivalent to a =+, |% with a $ arm).

For a **Dry Gate**, the following three things happen: (i) Compile the body into a Nock Formula. (ii) Compile the sample into a Nock Formula, (iii) Form a composite [formula payload subject] Nock Formula, which is dropped into a call site.  

**Main Idea:** Dry Gates are only compiled once. All we do is replace the sample, and drop the formula in place.

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

But what if we just wanted to duplicate any type,  without it being cast as a noun with an empty aura? With wet gates, we can accomplish this!


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
(4)  If the same, just insert the newly compiled formula+sample into the call site. **Avoid the nesting check - wet gates don't consider this (!!)**

Some other facts about wet gates:
- if the sample does not alter the formula, the formula will always recompile to the same thing, irrespective of the type of input we provide.
    - Example of improper sample usage (from tislec):

```
> =wet-gate-bad |*(f=@ud (f 3))
-find.$.+2
dojo: hoon expression failed
```

here, we try to use an @ud as a gate call. Obviously, there is no $ arm to call.  The compiler does not know beforehand if this will work or not.

- Eventhough the compiler never checks the sample for the wet gate, we still need to be mindful of how the sample is used (as seen above).

**Why do we use wet gates?**  When the typing information isn't well characterized beforehand, or we deal with problems where typing just doesnt matter (such as our doubling cell problem, above)

### Making P.P Strucutres:

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

- This is about Dry Gate Polymorphism. It works by substituting cores

-  **"For core b to nest within core a, the batteries of a and b must (i) have the same tree shape, and (ii) the product of each b arm must nest within the product of the a arm."**

- we also apply a payload test. This is where the "rules of variance" are applied and used.

- Key Idea: Variance rules apply to the input and output of a core, not directly to the core itself.

- "You are able to use core-variance rules to create programs which take other programs as arguments"

- "core variance ... since it impinges on how cores evaluate with other cores as inputs"

- A summary table of the metallic cores is below:

| Metal: | Relation: | Wat? | Involves: | Pay Load: | Context: | Cast Rune: | Other Notes: |
|---|---|---|---|---|---|---|---| 
| Zinc | Covariance | Specific Type Nests in Generic Type | Output | Read Only | Opaque |  ^& | PP Rep: "&" |
| Iron | Contravariance | Generic Type Nests in Specific Type | Input | Write Only | Opaque | \|~ |  PP Rep: "|" |
| Lead | Bivariant | Either/Or | ??? | Opaque | Opaque | \|? |  Rare - for completeness. PP rep: "?" |
| Gold | Invariant | Types mutually nest | Inputs and Outputs | Read and Write | Read and Write | NA |  Common everyday core. PP Rep: "." |
---

- Core terms of casting:  Gold -> {Zinc, Iron} 
- Because Lead Cores don't have a payload or sample, |? creates a lead trap.
- Define Opaquness to mean: Not exported to namespace, and cannot read and write.
- Payload address: +6.z
- Context Address: +7.z

### Outstanding Questions:

In (3) why do we compare the new formula to the old formula? Can it sometimes change, based on the input?

## References:

[1]: Example taken from timluc-miptev's [Wet Gate tutorial](https://blog.timlucmiptev.space/wetgates.html). Not my own!