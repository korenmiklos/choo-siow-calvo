# Derivation of the 3-Hop Covariance in the Firm–Manager GMRF

## 1. Model and goal

We use the additive model on the firm–manager bipartite graph:

$$
y_{im} = a_i + z_m + \varepsilon_{im},
$$
where
$$
\mathbb{E}[a_i] = \mathbb{E}[z_m] = 0, \quad 
\operatorname{Var}(a_i) = \sigma_a^2, \quad 
\operatorname{Var}(z_m) = \sigma_z^2,
$$
and $\varepsilon_{im}$ is i.i.d. and independent of all latent components $(a,z)$.

Latent firm and manager effects form a **Gaussian Markov Random Field (GMRF)** on the mobility graph, with correlation decay parameter $\rho \in (-1,1)$.  
If two nodes are \(k\) hops apart in the bipartite network, their covariance is proportional to $\rho^k$.

We want the covariance between two *matches* that are **three hops apart**:

- Manager $m_1$ works at firm $A$: $y_{A m_1}$
- Manager $m_2$ works at firm $B$, but also worked at $A$: $y_{B m_2}$

Thus the path is:
$$
m_1 \;-\; A \;-\; m_2 \;-\; B.
$$

Our goal is to derive
$$
\operatorname{Cov}(y_{A m_1}, y_{B m_2}).
$$

---

## 2. Graph distances and primitive covariances

Under the GMRF rule:

| Pair                              | Path length | Covariance                 |
| --------------------------------- | ----------- | -------------------------- |
| $a_A \leftrightarrow z_{m_2}$     | 1           | $\rho\,\sigma_a\sigma_z$   |
| $a_B \leftrightarrow z_{m_2}$     | 1           | $\rho\,\sigma_a\sigma_z$   |
| $a_A \leftrightarrow a_B$         | 2           | $\rho^2\,\sigma_a^2$       |
| $z_{m_1} \leftrightarrow z_{m_2}$ | 2           | $\rho^2\,\sigma_z^2$       |
| $z_{m_1} \leftrightarrow a_B$     | 3           | $\rho^3\,\sigma_a\sigma_z$ |

These are the **primitive covariances** implied by the network geometry.

---

## 3. Conditioning set: why $(a_A, z_{m_2})$?

In the 3-hop chain \(m_1 - A - m_2 - B\), the two **intermediate nodes** are $a_A$ and $z_{m_2}$.  
By the **Markov property** of the GMRF, once we condition on these intermediaries, the two endpoints become independent:

$$
Y_1 = y_{A m_1} \perp Y_2 = y_{B m_2} \mid (a_A, z_{m_2}).
$$

Thus, the minimal conditioning set that “screens off” all dependence is:
$$
S := (a_A, z_{m_2}).
$$

We can therefore apply the **law of total covariance**:
$$
\operatorname{Cov}(Y_1, Y_2)
= \mathbb{E}[\operatorname{Cov}(Y_1, Y_2 \mid S)]
+ \operatorname{Cov}(\mathbb{E}[Y_1 \mid S], \mathbb{E}[Y_2 \mid S]).
$$

---

## 4. Conditional expectations

### 4.1. Manager effects conditional on $a_A$

Since $(a_A, z_m)$ are jointly Gaussian,
$$
\mathbb{E}[z_m \mid a_A] 
= \frac{\operatorname{Cov}(z_m, a_A)}{\operatorname{Var}(a_A)}\,a_A 
= \frac{\rho\,\sigma_z}{\sigma_a}\,a_A.
$$

Define the residual
$$
u_m := z_m - \frac{\rho\,\sigma_z}{\sigma_a} a_A,
$$
so that
$$
\mathbb{E}[u_m \mid a_A] = 0, \quad \operatorname{Var}(u_m) = \sigma_z^2(1-\rho^2),
\quad u_{m_1} \perp u_{m_2} \mid a_A.
$$

Then:
$$
\mathbb{E}[Y_1 \mid a_A] = a_A + \mathbb{E}[z_{m_1} \mid a_A]
= \left(1 + \frac{\rho\,\sigma_z}{\sigma_a}\right)a_A.
$$
Since $z_{m_1}$ is not in $S$,
$$
\mathbb{E}[Y_1 \mid S] = \left(1 + \frac{\rho\,\sigma_z}{\sigma_a}\right)a_A.
$$

---

### 4.2. Firm \(B\) conditional on $(a_A, z_{m_2})$

We can project $a_B$ on its Markov neighbors $a_A$ and $z_{m_2}$:
$$
\mathbb{E}[a_B \mid a_A, z_{m_2}] = \beta_1 a_A + \beta_2 z_{m_2}.
$$

Compute the regression coefficients using joint covariances:
$$
\operatorname{Cov}(a_B, [a_A, z_{m_2}]) = [\rho^2\sigma_a^2,\ \rho\,\sigma_a\sigma_z],
$$
$$
\operatorname{Var}([a_A, z_{m_2}]) =
\begin{bmatrix}
\sigma_a^2 & \rho\,\sigma_a\sigma_z \\
\rho\,\sigma_a\sigma_z & \sigma_z^2
\end{bmatrix}.
$$

Solving gives:
$$
\beta_1 = 0, \qquad \beta_2 = \rho\,\frac{\sigma_a}{\sigma_z}.
$$
Hence:
$$
\mathbb{E}[a_B \mid S] = \rho\,\frac{\sigma_a}{\sigma_z}\,z_{m_2}.
$$

Finally:
$$
\mathbb{E}[Y_2 \mid S]
= \mathbb{E}[a_B \mid S] + z_{m_2}
= \left(1 + \rho\,\frac{\sigma_a}{\sigma_z}\right)z_{m_2}.
$$

---

## 5. Conditional covariance term

Given $S=(a_A,z_{m_2})$, the remaining residuals are independent:
- $Y_1 - \mathbb{E}[Y_1 \mid S] = u_{m_1} + \varepsilon_{A m_1}$,
- $Y_2 - \mathbb{E}[Y_2 \mid S] = (a_B - \mathbb{E}[a_B \mid S]) + \varepsilon_{B m_2}$.

Because these residuals are conditionally uncorrelated (by the Markov property),
$$
\mathbb{E}[\operatorname{Cov}(Y_1, Y_2 \mid S)] = 0.
$$

---

## 6. Covariance of conditional means

The total covariance therefore equals the covariance of the conditional expectations:
$$
\operatorname{Cov}(Y_1, Y_2)
= \operatorname{Cov}(\mathbb{E}[Y_1 \mid S], \mathbb{E}[Y_2 \mid S]).
$$

Plug in the expressions:
$$
\operatorname{Cov}(Y_1, Y_2)
= \operatorname{Cov}\!\left(
\left(1 + \frac{\rho\,\sigma_z}{\sigma_a}\right)a_A,\ 
\left(1 + \rho\,\frac{\sigma_a}{\sigma_z}\right)z_{m_2}
\right).
$$

Because $\operatorname{Cov}(a_A, z_{m_2}) = \rho\,\sigma_a\sigma_z$,
$$
\operatorname{Cov}(Y_1, Y_2)
= \left(1 + \frac{\rho\,\sigma_z}{\sigma_a}\right)
  \left(1 + \rho\,\frac{\sigma_a}{\sigma_z}\right)
  \cdot \rho\,\sigma_a\sigma_z.
$$

Expanding:
$$
\operatorname{Cov}(Y_1, Y_2)
= \rho\,\sigma_a\sigma_z
  + \rho^2(\sigma_a^2 + \sigma_z^2)
  + \rho^3\,\sigma_a\sigma_z.
$$

---

## 7. Final 3-hop covariance

$$
\operatorname{Cov}\big(y_{A m_1}, y_{B m_2}\big)
= \rho^2(\sigma_a^2 + \sigma_z^2)
+ \rho(1+\rho^2)\,\sigma_a\sigma_z
$$

---

