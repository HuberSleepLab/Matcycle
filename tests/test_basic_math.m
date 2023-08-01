% shared variable section

a = 2;


%% My old test element

a = 3;
assert(a + a == 2, "Addition doesn't work")
assert(1 - 1 == 2, "Subtraction doesn't work")


%% my new test element

assert(a == 2, "happy!")