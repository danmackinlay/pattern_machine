/*
 * Phenoynth.
 * ***********
 *
 * Another bloody genetic algorithm for supercollider.
 *
 * If you want to do some genetic algorithm business in supercollider there
 * are a lot of better-tested libraries on the market out there, e.g.
 *
 * redFrik's redGA http://www.fredrikolofsson.com/f0blog/?q=node/144
 * Batuhan's GAWorkbench http://www.fredrikolofsson.com/f0blog/?q=node/144
 * Dan Stowell's MCLD_Genetic http://www.mcld.co.uk/supercollider/ which I
 *   have mirrored with permission at
 *   https://github.com/howthebodyworks/MCLD_Genetic
 * Nick Collin's famous breakbeat evolver is probably online somewhere too
 *   but I got lost in his website trying to find it.
 *
 * There's nothing wrong with these libraries, and they solve a great many
 * problems admirably. You should probably use them unless you have a
 * demonstrated need to do otherwise.
 *
 * However, the first two don't solve the problem that I want to solve, which
 * is to explore the marvellous world of _phenotypic_ (rather than genotypic)
 * selection.
 *
 * Put loosely, _those _libraries work on strings of DNA and
 * select the fittest to solve a quasi-static problem. Think in-vitro genetic
 * engineering.
 *
 * _This_ library is in-vivo, spawning creatures who have DNA and also bodies,
 * and tests which ones survive when they battle against each other all
 * red in tooth and claw.
 *
 * This means I can try fun things like niche construction and co-evolution.
 * MCLD's library does this too, and I tried to evolve his code, but it is so
 * Synth-specific that it ended up being simpler to start again, at least for
 * the SCLang bits. I have, however, recycled and updated his lovely SynthDef
 * library.
 *
 * Additionally, I've written my codebase from the ground up to have nice
 * features like making Server-based interaction optional using trendy MVC
 * abstractions, and creating a 100% swappable GA operator architecture, so
 * that you can dynamically construct GAs from the interactive prompt without
 * subclassing. In fact, it's so flexible that you can implement genotypic
 * selection as a special case of phenotypic selection if you want.
 *
 * CREDITS:
 * Thanks to Martin Marier, Alex Whillas and Crucial Felix for tips that make
 * this go, James Nichols for the peer pressure to do it, and the Underbelly
 * Arts festival for funding initial development
 * http://underbellyarts.com.au/
 *
 * Enjoy.
 * Dan MacKinlay
 * 2012-02-01
 *
 *
 */
