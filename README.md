# jumpingSchedule
Julia port of schedule optimization code (MILP) originally written in Matlab

## What is this repository about?
In the context of renewable energy generation, it has become essential to compensate fluctuating electricity production with flexible on-demand delivery solutions.
The examples presented in this repository are from Combined Heat and Power Units (CHP) converting biomethane to electricity and heat.

From the plant owner's point of view, the objective is to maximize direct marketing revenue, which mainly depends on current prices at the European Power Exchange (EPEX).
Since prices are only known one day in advance, prediction algorithms have been developed to forecast future market development.
One such approach is published in the [GermanPowerMarket.database.toolbox](https://gitlab.com/M.Dotzauer/gpm_dbtb), which also served as a source of some of the raw data in this repository.

Mathematically, this kind of optimization problem is known as **mixed-integer linear programming** ([**MILP**](https://en.wikipedia.org/wiki/Linear_programming#Integer_unknowns)).

## Why did I create this repository?
I have been developing and running several schedule optimization codes in **Matlab** as part of my research work.
Apart from `intlinprog` (Matlab Optimization Toolbox™), I have mainly used [CBC](https://projects.coin-or.org/Cbc) through the great [OPTI toolbox](https://github.com/jonathancurrie/OPTI) by Jonathan Currie, which unfortunately is [no longer maintained](https://www.inverseproblem.co.nz/OPTI/index.php/Blog/OPTI-Toolbox-Development-has-Ceased).
This means that with the next Matlab update, all my scripts *could* stop working.

Also, I want to include more [free and open-source software](https://en.wikipedia.org/wiki/Free_and_open-source_software) in my research, and showcase its usage so others can benefit from it.

Those are the main reasons I decided to rewrite some of my scripts in **Julia**.
Initially, I have started using the [JuMP modeling language for mathematical optimization](https://jump.dev/JuMP.jl/stable/), hence the name **jumpingSchedule**.

## Disclaimer
This repository also serves as a "learning-by-doing" project for my Julia skills.
Please be aware there can be dramatic changes as my knowledge evolves.
Also, consider any of the scripts work-in-progress.

If you can and are willing to improve anything in or contribute to this repository, I am happy to receive your pull request.
