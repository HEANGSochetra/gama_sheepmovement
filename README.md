# Sheep Movement Simulation

This project is an agent-based sheep movement model built with the GAMA Platform. It studies how flock size, vegetation, a herding dog, and obstacles affect sheep gathering, movement, and landscape trampling.

## Model

The simulation contains four agent types:

- **Sheep** move toward vegetation, follow nearby sheep, maintain separation, flee from dogs, and avoid obstacles.
- **Dogs** chase the nearest sheep. Their chase speed can be changed in the experiment parameters.
- **Vegetation** acts as a destination for sheep.
- **Obstacles** are randomly positioned rocks and trees that cause sheep to change direction.

The landscape is a `100 m × 100 m` grid. Grid cells record how often sheep walk over them and change color as trampling increases.

The main model is [`SheepMovement.gaml`](SheepMovement.gaml).

## Running the model

1. Open `SheepMovement.gaml` in GAMA.
2. Select the **Sheep Movement** experiment.
3. Configure the number of sheep, vegetation patches, obstacles, dogs, and dog chase speed.
4. Run the experiment and observe the environment, monitors, and charts.
5. Enable **Export per-cycle CSV** to write detailed values to `sheep_movement_timeseries.csv`.

The model also includes an **Obstacle comparison (batch)** experiment. It compares 0, 5, 15, and 30 obstacles using 40 sheep, 10 repetitions per treatment, and 500 cycles per simulation. Its output is written to `obstacle_comparison_results.csv`.

## Measurements

| Measurement | Meaning |
|---|---|
| Mean distance travelled | Average cumulative distance travelled by each sheep |
| Mean flock spacing | Average distance from a sheep to its nearest neighbour; lower values indicate tighter gathering |
| Obstacle encounters | Number of times sheep enter an obstacle's perception area |
| Trampled area | Percentage of landscape cells visited by at least one sheep |
| Mean trampling intensity | Average number of visits to cells that have been trampled |

## Recorded experiments

Each numbered folder contains the screenshots for the corresponding experiment.

| Folder | Experiment |
|---:|---|
| `1` | 20 sheep |
| `2` | 60 sheep |
| `3` | 20 sheep with vegetation |
| `4` | 60 sheep with vegetation |
| `5` | 20 sheep with vegetation and a dog |
| `6` | 60 sheep with vegetation and a dog |
| `7` | 20 sheep with vegetation and 5 obstacles |
| `8` | 60 sheep with vegetation and 5 obstacles |
| `9` | 20 sheep with vegetation and 20 obstacles |
| `10` | 60 sheep with vegetation and 20 obstacles |
| `11` | 20 sheep with vegetation, a dog, and 10 obstacles |
| `12` | 60 sheep with vegetation, a dog, and 10 obstacles |

## Recorded results

Experiments 1–2 ended at cycle 15. Experiments 3–12 ended at cycle 50. Because the durations differ, experiments 1–2 should not be compared directly with experiments 3–12.

| Experiment | Mean distance (m) | Flock spacing (m) | Trampled area | Obstacle encounters |
|---:|---:|---:|---:|---:|
| 1 | 15.07 | 1.98 | 1.51% | 0 |
| 2 | 13.44 | 2.08 | 4.15% | 0 |
| 3 | 57.49 | 1.07 | 6.69% | 0 |
| 4 | 50.05 | 1.08 | 16.19% | 0 |
| 5 | 57.17 | 1.65 | 6.45% | 0 |
| 6 | 57.24 | 1.60 | 18.32% | 0 |
| 7 | 57.85 | 2.06 | 5.46% | 156 |
| 8 | 56.96 | 1.88 | 15.16% | 369 |
| 9 | 55.55 | 5.94 | 3.97% | 235 |
| 10 | 52.51 | 1.40 | 9.73% | 682 |
| 11 | 42.31 | 3.77 | 4.09% | 65 |
| 12 | 55.44 | 2.12 | 12.38% | 635 |

## Evaluation

- Increasing the flock from 20 to 60 sheep substantially increased the percentage of land trampled.
- Vegetation produced the tightest groups. Experiments 3 and 4 both reached a mean flock spacing of approximately `1.07 m`.
- Adding a dog increased flock spacing by approximately 49–55% compared with vegetation alone. The dog therefore disturbed and spread the flock.
- Five obstacles slightly reduced landscape coverage and increased flock spacing.
- Twenty obstacles strongly fragmented the 20-sheep flock, which reached the largest recorded spacing of `5.94 m`.
- The 60-sheep flock remained better connected in environments containing many obstacles, although it caused more total trampling and obstacle encounters.
- Combining a dog with 10 obstacles reduced movement and increased separation for the 20-sheep flock. The 60-sheep flock remained more cohesive but produced many more encounters and greater landscape impact.

## Conclusion

Vegetation encourages sheep to gather, while dogs and obstacles disrupt the flock. A high obstacle density can divide a small flock and restrict its movement. Larger flocks generally remain connected more effectively in difficult environments, but they cause substantially more landscape trampling.

These results come from one random run per experiment. For stronger statistical conclusions, all experiments should use the same duration and be repeated at least 10 times. Results should be reported as mean ± standard deviation, and obstacle encounters should also be divided by the number of sheep for fair comparisons between flock sizes.

The original extracted result notes are available in [`result.txt`](result.txt).
