#include "main.h"

/**
 * @brief Execute a known value test to verify the functionality of the source.
 * 
 * We are going to test the functionality of the source using a known value
 * test. We first define two polynomials poly_one, poly_two of size NTRU_P. We
 * then define the expected result. We are computing:
 * 
 * poly_one * poly_two % (x^761 - x - 1) % 4591
 * 
 * poly_one is a polynomial with integer coefficients in Z_q
 * poly_two is a polynomial with integer coefficients in {-1, 0, 1}
 */

int main()
{
    /**
     * @brief Define the (input, result) polynomials for our known value test.
     */

    int32_t poly_one[NTRU_P] = {3890, 4169, 1, 4362, 3221, 2092, 1234, 1295, 235, 4319, 3023, 4176, 1074, 4374, 4016, 4251, 765, 3272, 667, 4008, 3153, 3751, 1259, 2059, 816, 190, 75, 3267, 4070, 2115, 3293, 284, 3570, 2082, 68, 51, 881, 1627, 1590, 1911, 8, 1956, 951, 4044, 2871, 1837, 1211, 898, 3915, 4195, 1139, 1339, 1481, 1786, 2923, 2264, 453, 1697, 2860, 741, 520, 4441, 418, 1578, 3237, 2483, 2663, 3766, 2862, 4310, 4408, 3412, 1926, 1186, 587, 1650, 3675, 612, 2394, 2524, 3539, 3023, 1229, 4474, 1931, 1305, 419, 863, 26, 3195, 1252, 297, 3679, 2723, 324, 3290, 2065, 3595, 3372, 3658, 1054, 2569, 1771, 2709, 4522, 4530, 412, 702, 132, 769, 3365, 2227, 811, 320, 1891, 2179, 4166, 4010, 523, 3148, 3873, 2512, 7, 2586, 3737, 2895, 284, 2906, 693, 3602, 4269, 389, 1025, 1267, 1699, 4309, 57, 3647, 3255, 341, 1612, 1733, 3866, 1668, 4416, 4242, 4289, 2999, 751, 1817, 2618, 3242, 1343, 3606, 384, 2547, 1256, 3471, 3657, 1998, 4058, 4462, 3612, 1178, 2278, 4010, 1580, 290, 2978, 547, 2406, 2701, 1104, 1537, 4209, 1419, 3496, 2933, 1668, 4161, 2404, 3290, 774, 364, 54, 2413, 3149, 2277, 655, 2279, 2520, 2214, 2391, 4044, 2694, 1042, 2239, 3469, 3511, 1061, 1175, 2553, 1520, 324, 3339, 130, 2322, 2304, 180, 1340, 1832, 3078, 3896, 2340, 99, 2254, 4001, 4158, 939, 4470, 852, 1932, 164, 2814, 278, 4173, 713, 1209, 2954, 1079, 711, 1073, 589, 404, 4236, 1940, 2698, 3708, 4095, 515, 2546, 600, 54, 116, 1720, 1008, 4461, 2853, 3431, 2845, 950, 1579, 4315, 2136, 3441, 4503, 4243, 2960, 423, 314, 1023, 3130, 4097, 1248, 278, 1729, 3115, 809, 42, 386, 4292, 935, 801, 1135, 1745, 2077, 3398, 462, 3497, 221, 2808, 3886, 3069, 4027, 632, 3154, 2830, 967, 1439, 3102, 4004, 2020, 885, 3914, 3717, 1224, 173, 3290, 4091, 1129, 1863, 267, 263, 4020, 4051, 4066, 465, 2131, 2336, 4147, 2329, 1498, 3110, 4413, 1603, 4015, 110, 722, 1893, 3969, 853, 2727, 1759, 2293, 546, 4277, 586, 2397, 3157, 3831, 3159, 3975, 2649, 1803, 2386, 3622, 2081, 3117, 2405, 147, 2667, 2403, 1691, 1211, 2815, 3613, 1361, 1829, 1641, 4063, 682, 3442, 942, 3507, 3097, 2233, 2532, 3980, 3493, 464, 3865, 1938, 1928, 2733, 3112, 3433, 4145, 4466, 4284, 2609, 3757, 4429, 699, 2236, 3219, 2693, 2300, 3343, 4010, 173, 4341, 1563, 2685, 3277, 3287, 1987, 4163, 4101, 278, 4265, 834, 822, 2847, 410, 1489, 1582, 2621, 763, 2124, 3128, 1326, 325, 1563, 4542, 4545, 4077, 14, 3066, 1630, 4442, 4354, 497, 3983, 4581, 2168, 1523, 484, 2381, 441, 3770, 3113, 3297, 960, 3899, 1173, 394, 2582, 2712, 1262, 3424, 575, 3255, 274, 338, 245, 2717, 817, 1903, 2559, 3228, 1622, 3382, 2439, 3563, 3367, 2617, 180, 1315, 750, 3012, 2703, 1015, 3489, 2511, 3635, 1424, 2537, 2472, 240, 3462, 4149, 819, 3586, 3072, 4053, 1734, 2213, 1281, 1743, 2751, 2546, 949, 2918, 2817, 2105, 808, 1469, 407, 1197, 54, 379, 1785, 913, 3124, 2119, 1206, 2291, 4015, 2460, 3363, 2396, 4069, 2614, 2722, 44, 967, 4026, 3324, 266, 3382, 1314, 3366, 2875, 1540, 1305, 2015, 97, 1596, 763, 1519, 3532, 1276, 1694, 4565, 2292, 2047, 1430, 1970, 553, 3739, 3090, 1497, 2285, 2212, 25, 3429, 4154, 2088, 88, 3951, 1188, 1944, 2965, 4196, 1635, 3234, 3690, 3677, 35, 3024, 2078, 1688, 410, 2885, 1557, 4336, 1291, 4017, 2065, 3114, 3277, 1810, 2965, 3760, 119, 2086, 2964, 2032, 3185, 3653, 405, 4268, 1570, 2119, 987, 4417, 1854, 3031, 314, 3136, 3524, 798, 3098, 3042, 3202, 3821, 756, 4261, 1936, 1375, 3074, 4066, 1654, 1206, 2943, 3677, 1164, 3511, 7, 2240, 477, 4152, 3441, 3230, 3676, 847, 567, 4141, 2379, 3724, 2901, 1268, 3809, 553, 4449, 2934, 1285, 1437, 3138, 1766, 2902, 3083, 2550, 1522, 4351, 883, 174, 3621, 2422, 840, 3887, 731, 2256, 353, 3069, 3850, 2519, 750, 3624, 3376, 464, 4017, 1315, 3549, 3717, 2199, 4419, 4169, 2236, 1309, 132, 2583, 2623, 2207, 3757, 227, 4257, 1255, 2834, 2797, 1732, 501, 4314, 2329, 99, 2222, 1738, 25, 1828, 4048, 1302, 3432, 603, 3343, 2114, 693, 4179, 2293, 1445, 2559, 899, 4361, 965, 3144, 4272, 3062, 533, 224, 2394, 3346, 3931, 354, 520, 4248, 2878, 2320, 3183, 472, 1460, 1440, 202, 745, 1778, 2775, 4018, 2699, 4589, 4494, 3088, 1163, 3346, 3697, 3646, 2407, 3207, 3856, 1339, 3160, 2581, 2970, 116, 4358, 3283, 1555, 2623, 2479, 0, 115, 777, 1080, 164, 3129, 2478, 1744, 904, 458, 2236, 1515, 2673, 18, 2639, 2262, 244, 931, 4355, 2628, 2766, 4361, 1942, 843, 3101, 1201, 3416, 2646, 338, 220, 3123, 3398, 1910, 2430, 4477, 989, 4421, 200, 1399, 3967, 416, 1835, 2058, 3097, 1656};
    int32_t poly_two[NTRU_P] = {0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, -1, -1, 0, 1, 1, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 1, 1, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, -1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 1, 0, 0, -1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, -1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, -1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, -1, 1, 1, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, -1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, -1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, -1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, -1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, -1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, -1, 0, 0, 1, 1, 0, 0, 0, -1, 0, -1, -1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, -1, 1, 0, 0, 0, 0, 0, -1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, -1, 1, -1, 1, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, -1, -1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, -1, 1, 0, 1, 0, 0, -1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, -1, 0, -1, 0, -1, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, -1, 0, 0, 0, 1, -1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1};
    int32_t result[NTRU_P] = {4245, 3406, 3907, 1794, 532, 196, 1794, 2443, 3723, 2425, 3314, 954, 2216, 4023, 810, 3703, 3889, 2134, 2594, 846, 3614, 1261, 3615, 4264, 2249, 3172, 1752, 4473, 3531, 1466, 2596, 538, 3569, 3731, 65, 1049, 2797, 4567, 3395, 2222, 568, 4463, 3990, 1801, 598, 1880, 2145, 1767, 245, 561, 2705, 4032, 1081, 2397, 2963, 435, 3517, 763, 4169, 2883, 2770, 2377, 2338, 1495, 858, 1525, 37, 2010, 671, 1508, 3638, 3711, 1643, 4309, 987, 4031, 2460, 3770, 920, 651, 354, 4392, 242, 2464, 3792, 3723, 2579, 2737, 3193, 2065, 3583, 743, 4142, 2286, 978, 2190, 1262, 183, 3213, 4510, 4391, 4275, 1599, 3266, 1817, 902, 342, 242, 1089, 506, 3147, 3733, 2562, 2293, 639, 1546, 1176, 2105, 1228, 2419, 2474, 4430, 2175, 916, 2688, 1737, 2181, 945, 1206, 215, 891, 2942, 1317, 17, 325, 1661, 3998, 4242, 1666, 3929, 4187, 2232, 3869, 556, 2993, 4418, 2211, 4295, 3446, 3553, 4486, 1045, 4363, 1415, 973, 3303, 3, 3981, 2930, 3229, 605, 4157, 2406, 4511, 2724, 3886, 1231, 1053, 3420, 1771, 1725, 2161, 967, 2304, 856, 3099, 564, 1171, 2611, 1290, 1964, 3680, 1271, 1793, 2648, 346, 3332, 2074, 1559, 4370, 1019, 3155, 3307, 3932, 3954, 858, 3346, 1038, 4077, 3524, 4354, 3016, 2043, 330, 2371, 3917, 946, 735, 2466, 4158, 4388, 4378, 1209, 3261, 1157, 4193, 1497, 2010, 3684, 4425, 4130, 2691, 3908, 1064, 692, 2548, 1277, 2615, 1879, 4201, 939, 210, 1452, 4037, 253, 1454, 2121, 976, 4406, 264, 4171, 4259, 3933, 2854, 2799, 4026, 413, 2242, 921, 655, 1061, 2139, 2551, 2982, 428, 370, 1451, 2969, 183, 1291, 4309, 4140, 1581, 3419, 2426, 501, 4246, 4, 4448, 1773, 3618, 1170, 3059, 1916, 1791, 1438, 2717, 2896, 3931, 3802, 1431, 2119, 946, 488, 2800, 4245, 3244, 4049, 3030, 2559, 3381, 4282, 2534, 3896, 2685, 1268, 3472, 538, 2212, 3880, 1665, 3070, 675, 319, 4232, 3382, 4264, 4073, 3697, 2324, 622, 612, 1713, 2554, 3039, 1866, 2851, 666, 192, 2976, 3069, 2584, 2252, 590, 3035, 2603, 1373, 4513, 3215, 3439, 3928, 2190, 3476, 2224, 996, 2504, 3356, 2443, 929, 985, 1034, 2187, 2391, 3625, 4057, 3973, 371, 241, 2302, 1689, 533, 2082, 2111, 2700, 3518, 2602, 774, 1099, 3765, 2722, 1559, 146, 413, 3041, 1569, 1201, 3533, 165, 2715, 1441, 3964, 2406, 2357, 1214, 2295, 2001, 397, 751, 1307, 1756, 1585, 2047, 3555, 2304, 277, 3713, 667, 3234, 1438, 3022, 2241, 2703, 2163, 2961, 21, 1387, 2651, 3378, 3694, 4562, 577, 1491, 4234, 1231, 1321, 924, 111, 3703, 2579, 2778, 3917, 931, 4111, 4201, 4358, 741, 3925, 3624, 646, 1281, 1307, 2326, 960, 556, 2992, 2209, 3873, 1629, 3297, 3575, 2837, 3591, 1487, 4144, 625, 1553, 909, 4150, 4126, 4193, 1603, 238, 4275, 4056, 561, 4165, 96, 3792, 4255, 1343, 3443, 3048, 2927, 3981, 2977, 3107, 3562, 1153, 967, 4417, 1283, 875, 3159, 2434, 608, 4089, 179, 1101, 556, 3205, 1478, 2161, 1154, 1793, 2204, 3735, 4205, 2293, 254, 3631, 4127, 32, 1869, 861, 1181, 4268, 4342, 2692, 4209, 3907, 2983, 3979, 836, 1041, 3789, 4464, 2926, 4261, 3666, 642, 4526, 2960, 770, 1564, 1448, 1048, 2972, 3720, 3006, 218, 3864, 4274, 1348, 7, 601, 3998, 795, 2376, 2495, 1506, 3733, 2851, 1207, 2207, 2050, 2924, 4493, 4037, 3230, 1381, 2975, 2339, 480, 2588, 4080, 2361, 4147, 2021, 810, 2202, 3431, 1303, 4540, 1308, 3142, 3867, 2376, 2855, 1942, 4091, 213, 829, 2826, 814, 3728, 2955, 2874, 764, 159, 2799, 4425, 3, 4107, 684, 3466, 1019, 774, 1067, 2825, 1686, 3534, 3032, 229, 222, 2668, 2028, 2715, 1838, 2476, 95, 4422, 395, 416, 3162, 1983, 3542, 478, 3354, 2203, 3827, 1638, 4587, 422, 1034, 4467, 4589, 2050, 3713, 2323, 1461, 2970, 4282, 561, 1843, 1449, 4185, 465, 3612, 1732, 4519, 760, 3541, 3884, 139, 4016, 2577, 4466, 4442, 3618, 2698, 2950, 1985, 1027, 1743, 1878, 1960, 3820, 2886, 3497, 1673, 1991, 45, 3040, 3337, 1728, 3007, 330, 76, 172, 2453, 294, 982, 1035, 1802, 1798, 3174, 2542, 3313, 4438, 1189, 1862, 3560, 3936, 3804, 1834, 4281, 789, 2631, 1675, 110, 1549, 2744, 2444, 3512, 2966, 3528, 793, 283, 77, 765, 3612, 1245, 1067, 3489, 4355, 3029, 671, 2968, 4157, 1521, 1005, 3426, 1918, 4589, 2151, 3077, 3256, 4036, 2128, 2734, 1884, 311, 1101, 143, 422, 1970, 4429, 1018, 3016, 351, 4403, 4480, 2927, 3702, 608, 3735, 1452, 1469, 1923, 232, 80, 3278, 380, 1751, 283, 3185, 4062, 1284, 2483, 3199, 1372, 3975, 2162, 3186, 1525, 1620, 1767, 518, 782, 822, 2139, 2844, 1330, 3811, 4419, 1795, 1035, 1322, 4272, 4456, 1831, 4304, 740, 1046, 1510, 3457, 4496, 3900, 803, 1777, 1808, 795, 1020, 2711, 267, 1523, 112, 4120, 1088, 3729, 1226};

    /**
     * @brief Zero pad the input polynomials to size 1536.
     */

    int32_t A_vec[GPR], B_vec[GPR];

    pad(A_vec, poly_one);
    pad(B_vec, poly_two);

    /**
     * @brief Compute the forward Good's permutation.
     * 
     * This deconstructs the 'clunky' zero padded arrays of integer coefficients
     * into 3 size-512 NTTs.
     */

    int32_t A_mat[GP0][GP1], B_mat[GP0][GP1];

    goods_forward(A_mat, A_vec);
    goods_forward(B_mat, B_vec);

    /**
     * @brief Compute the iterative inplace forward NTTs.
     * 
     * This computes the forward NTT transformation of our size-512 polynomials.
     */

    for (size_t idx = 0; idx < GP0; idx++)
    {
        ntt_forward(A_mat[idx], NTT_Q);
        ntt_forward(B_mat[idx], NTT_Q);
    }

    /**
     * @brief Compute the point-wise multiplication of the integer coefficients.
     * 
     * Be careful with these smaller polynomial multiplications. We are not
     * actually computing the result 'point-wise'. Instead we multiply two
     * degree 2 polynomials and reduce the result mod (x^3 - 1). E.g.:
     * 
     * (
     *   { F[0][0], F[1][0], F[2][0] } *
     *   { G[0][0], G[1][0], G[2][0] }
     * ) % (X^3 - 1)
     * 
     * = C[0][0], C[1][0], C[2][0]
     */

    int32_t C_mat[GP0][GP1];

    for (size_t idx = 0; idx < GP1; idx++)
    {
        /* Define an accumulator to store temporary values. It is important that
         * we (re)initialize this with zeros at each iteration of the loop */
        int32_t accum[2 * GP0 - 1] = {0, 0, 0, 0, 0};

        /* Obtain two degree 2 polynomials from A_mat, B_mat */
        int32_t F[GP0] = {A_mat[0][idx], A_mat[1][idx], A_mat[2][idx]};
        int32_t G[GP0] = {B_mat[0][idx], B_mat[1][idx], B_mat[2][idx]};

        /* Multiply the two polynomials naively */
        for (size_t n = 0; n < GP0; n++)
        {
            for (size_t m = 0; m < GP0; m++)
            {
                accum[n + m] += multiply_modulo(F[n], G[m], NTT_Q);
            }
        }

        /* Reduce the result mod (x^3 - 1) */
        for (size_t p = 2 * GP0 - 2; p >= GP0; p--)
        {
            if (accum[p] > 0)
            {                               /* x^p is nonzero */
                accum[p - GP0] += accum[p]; /* add x^p into x^0 */
                accum[p] = 0;               /* zero x^p */
            }
        }

        /* Store the result */
        C_mat[0][idx] = accum[0];
        C_mat[1][idx] = accum[1];
        C_mat[2][idx] = accum[2];
    }

    /**
     * @brief Compute the iterative inplace inverse NTT.
     * 
     * This computes the inverse NTT transformation of our size-512 polynomials.
     */

    for (size_t idx = 0; idx < GP0; idx++)
    {
        ntt_inverse(C_mat[idx], NTT_Q);
    }

    /**
     * @brief Compute the inverse Good's permutation.
     * 
     * This undoes the forward Good's permutation and constructs an array of
     * integer coefficients from the deconstructed smaller NTT friendly matrix.
     */

    int32_t C_vec[GPR];

    goods_inverse(C_vec, C_mat);

    /**
     * @brief Reduce the result of the multiplication mod (x^761 - x - 1).
     */

    reduce_terms_761(C_vec);

    /**
     * @brief Ensure the result is correct in the integer domain.
     * 
     * Before we can further reduce the integer coefficients we need to ensure
     * that the result is correct in the integer domain. We therefore reduce all
     * 761 integer coefficients mod 6984193.
     */

    for (size_t idx = 0; idx < NTRU_P; idx++)
    {
        C_vec[idx] = modulo(C_vec[idx], NTT_Q);
    }

    /**
     * @brief Reduce the integer coefficients mod 4591 and store the result.
     * 
     * This loop iterates over the first 761 integer coefficients, reduces them
     * mod 4591 and stores them. This removes the zero padding.
     */

    int32_t poly_out[NTRU_P];

    for (size_t idx = 0; idx < NTRU_P; idx++)
    {
        poly_out[idx] = modulo(C_vec[idx], NTRU_Q);
    }

    /**
     * @brief Test the result of the computation against the known test values
     */

    for (size_t idx = 0; idx < NTRU_P; idx++)
    {
        if (poly_out[idx] != result[idx])
        {
            printf("%s\n", "This is not correct!");
            printf("%s%ld\n", "Error at index: ", idx);
            return -1;
        }
    }

    printf("%s\n", "This is correct!");
    return 0;
}
