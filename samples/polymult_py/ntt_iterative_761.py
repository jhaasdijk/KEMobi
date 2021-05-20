#!/usr/bin/env python3

"""
This script can be used to perform NTT based polynomial multiplication of
two polynomials for the NTRU LPRime 'kem/ntrulpr761' parameter set.

While 761 is not an NTT friendly prime and the reduction polynomial is not
of the form x^n + 1 or x^n - 1, we can use Good's permutation after padding
to size 1536 to perform 3 size 512 NTTs instead. These smaller size - 512
cyclic NTTs are used to multiply polynomials in Z_6984193 [x] / (x^512 - 1).
"""

from lib_common import Goods
from lib_common import NTT
from lib_common import pad
from lib_common import reduce_q

# Define the original and NTT 'suitable' parameters
VAR_Q, VAR_P, NEW_Q = 4591, 761, 6984193
P_0, P_1, P0P1 = 3, 512, 1536

# These are the roots for a size - 512 cyclic NTT, i.e. we are multiplying
# polynomials in Z_6984193 [x] / (x^512 - 1). Remember that the inverse roots
# have been reordered
roots = [1, 1, 1888710, 1, 1888710, 2249918, 1189439, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 5503199, 1118760, 1516650, 1136094, 1305215, 3924598, 4044239, 6251766, 3905570, 978083, 930959, 6064175, 3894385, 2940558, 6629701, 92432, 5801064, 4976760, 5102405, 6225518, 1190023, 4238421, 923827, 1308559, 4878190, 1687037, 888587, 2527449, 1082755, 3564685, 2493111, 6787824, 1355126, 5676487, 862290, 6701195, 1866623, 647018, 6767961, 1144955, 3519122, 2849661, 774651, 435412, 231691, 2496195, 6538397, 23955, 683141, 2407483, 6863121, 6550086, 1450505, 5657528, 6461287, 2972484, 4167428, 3142354, 1373895, 3110809, 2777653, 4425680, 665089, 4244789, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 5503199, 1118760, 1516650, 1136094, 1305215, 3924598, 4044239, 6251766, 3905570, 978083, 930959, 6064175, 3894385, 2940558, 6629701, 92432, 5801064, 4976760, 5102405, 6225518, 1190023, 4238421, 923827, 1308559, 4878190, 1687037, 888587, 2527449, 1082755, 3564685, 2493111, 6787824, 1355126, 5676487, 862290, 6701195, 1866623, 647018, 6767961, 1144955, 3519122, 2849661, 774651, 435412, 231691, 2496195, 6538397, 23955, 683141, 2407483, 6863121, 6550086, 1450505, 5657528, 6461287, 2972484, 4167428, 3142354, 1373895, 3110809, 2777653, 4425680, 665089, 4244789, 6358, 2590413, 1351380, 5556336, 6763602, 2621612, 6045621, 2624175, 5914879, 2029063, 4083230, 628191, 4991048, 149857, 4813523, 4044651, 440308, 6262170, 4991238, 2810914, 6352749, 6199440, 6365889, 2026918, 5214196, 882352, 3817389, 4692044, 3272569, 6801306, 3255215, 6945715, 2608026, 131613, 5050988, 2642920, 3999892, 2071852, 2992250, 2253181, 6435502, 3362923, 2228956, 3440536, 2688039, 4500902, 3181154, 6611809, 5282741, 3507854, 6481066, 1319217, 3556037, 1380592, 474465, 5938899, 2940212, 6110290, 3850420, 875985, 1833815, 6593827, 409841, 5700727, 5516505, 3167606, 4674360, 1630090, 1335686, 5056688, 4457129, 1685865, 2807945, 2719944, 3425851, 3279290, 1535645, 6367296, 2034203, 1010444, 6625872, 3845790, 6498698, 2421713, 2285215, 2864124, 6969946, 1644259, 5715100, 5444991, 6408202, 5876842, 4726185, 560945, 4065821, 1656445, 4381139, 3779115, 6832508, 2620510, 1845127, 50767, 1082965, 2094784, 4207497, 1147996, 1374993, 2609068, 6410848, 2721314, 1211390, 5637837, 6226625, 4410051, 5469647, 5688122, 3176030, 1969074, 6823713, 6811207, 5463175, 4294752, 4983160, 6273239, 4277870, 6144036, 3199097, 1446710]
roots_inv = [1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 2739404, 6319104, 2558513, 4206540, 3873384, 5610298, 3841839, 2816765, 4011709, 522906, 1326665, 5533688, 434107, 121072, 4576710, 6301052, 6960238, 445796, 4487998, 6752502, 6548781, 6209542, 4134532, 3465071, 5839238, 216232, 6337175, 5117570, 282998, 6121903, 1307706, 5629067, 196369, 4491082, 3419508, 5901438, 4456744, 6095606, 5297156, 2106003, 5675634, 6060366, 2745772, 5794170, 758675, 1881788, 2007433, 1183129, 6891761, 354492, 4043635, 3089808, 920018, 6053234, 6006110, 3078623, 732427, 2939954, 3059595, 5678978, 5848099, 5467543, 5865433, 1480994, 5537483, 3785096, 840157, 2706323, 710954, 2001033, 2689441, 1521018, 172986, 160480, 5015119, 3808163, 1296071, 1514546, 2574142, 757568, 1346356, 5772803, 4262879, 573345, 4375125, 5609200, 5836197, 2776696, 4889409, 5901228, 6933426, 5139066, 4363683, 151685, 3205078, 2603054, 5327748, 2918372, 6423248, 2258008, 1107351, 575991, 1539202, 1269093, 5339934, 14247, 4120069, 4698978, 4562480, 485495, 3138403, 358321, 5973749, 4949990, 616897, 5448548, 3704903, 3558342, 4264249, 4176248, 5298328, 2527064, 1927505, 5648507, 5354103, 2309833, 3816587, 1467688, 1283466, 6574352, 390366, 5150378, 6108208, 3133773, 873903, 4043981, 1045294, 6509728, 5603601, 3428156, 5664976, 503127, 3476339, 1701452, 372384, 3803039, 2483291, 4296154, 3543657, 4755237, 3621270, 548691, 4731012, 3991943, 4912341, 2984301, 4341273, 1933205, 6852580, 4376167, 38478, 3728978, 182887, 3711624, 2292149, 3166804, 6101841, 1769997, 4957275, 618304, 784753, 631444, 4173279, 1992955, 722023, 6543885, 2939542, 2170670, 6834336, 1993145, 6356002, 2900963, 4955130, 1069314, 4360018, 938572, 4362581, 220591, 1427857, 5632813, 4393780, 6977835, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 2739404, 6319104, 2558513, 4206540, 3873384, 5610298, 3841839, 2816765, 4011709, 522906, 1326665, 5533688, 434107, 121072, 4576710, 6301052, 6960238, 445796, 4487998, 6752502, 6548781, 6209542, 4134532, 3465071, 5839238, 216232, 6337175, 5117570, 282998, 6121903, 1307706, 5629067, 196369, 4491082, 3419508, 5901438, 4456744, 6095606, 5297156, 2106003, 5675634, 6060366, 2745772, 5794170, 758675, 1881788, 2007433, 1183129, 6891761, 354492, 4043635, 3089808, 920018, 6053234, 6006110, 3078623, 732427, 2939954, 3059595, 5678978, 5848099, 5467543, 5865433, 1480994, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 1, 5095483, 5794754, 4734275, 1, 5095483, 1]

# Define objects to interact with the implemented Good's and NTT methods
goods = Goods(P_0, P_1, P0P1)
ntt = NTT(NEW_Q, P_1, roots, roots_inv)

# Define two polynomials A, B
# *. A is a polynomial with integer coefficients in Z_q
# *. B is a polynomial with integer coefficients in {-1, 0, 1}
A = [3890, 4169, 1, 4362, 3221, 2092, 1234, 1295, 235, 4319, 3023, 4176, 1074, 4374, 4016, 4251, 765, 3272, 667, 4008, 3153, 3751, 1259, 2059, 816, 190, 75, 3267, 4070, 2115, 3293, 284, 3570, 2082, 68, 51, 881, 1627, 1590, 1911, 8, 1956, 951, 4044, 2871, 1837, 1211, 898, 3915, 4195, 1139, 1339, 1481, 1786, 2923, 2264, 453, 1697, 2860, 741, 520, 4441, 418, 1578, 3237, 2483, 2663, 3766, 2862, 4310, 4408, 3412, 1926, 1186, 587, 1650, 3675, 612, 2394, 2524, 3539, 3023, 1229, 4474, 1931, 1305, 419, 863, 26, 3195, 1252, 297, 3679, 2723, 324, 3290, 2065, 3595, 3372, 3658, 1054, 2569, 1771, 2709, 4522, 4530, 412, 702, 132, 769, 3365, 2227, 811, 320, 1891, 2179, 4166, 4010, 523, 3148, 3873, 2512, 7, 2586, 3737, 2895, 284, 2906, 693, 3602, 4269, 389, 1025, 1267, 1699, 4309, 57, 3647, 3255, 341, 1612, 1733, 3866, 1668, 4416, 4242, 4289, 2999, 751, 1817, 2618, 3242, 1343, 3606, 384, 2547, 1256, 3471, 3657, 1998, 4058, 4462, 3612, 1178, 2278, 4010, 1580, 290, 2978, 547, 2406, 2701, 1104, 1537, 4209, 1419, 3496, 2933, 1668, 4161, 2404, 3290, 774, 364, 54, 2413, 3149, 2277, 655, 2279, 2520, 2214, 2391, 4044, 2694, 1042, 2239, 3469, 3511, 1061, 1175, 2553, 1520, 324, 3339, 130, 2322, 2304, 180, 1340, 1832, 3078, 3896, 2340, 99, 2254, 4001, 4158, 939, 4470, 852, 1932, 164, 2814, 278, 4173, 713, 1209, 2954, 1079, 711, 1073, 589, 404, 4236, 1940, 2698, 3708, 4095, 515, 2546, 600, 54, 116, 1720, 1008, 4461, 2853, 3431, 2845, 950, 1579, 4315, 2136, 3441, 4503, 4243, 2960, 423, 314, 1023, 3130, 4097, 1248, 278, 1729, 3115, 809, 42, 386, 4292, 935, 801, 1135, 1745, 2077, 3398, 462, 3497, 221, 2808, 3886, 3069, 4027, 632, 3154, 2830, 967, 1439, 3102, 4004, 2020, 885, 3914, 3717, 1224, 173, 3290, 4091, 1129, 1863, 267, 263, 4020, 4051, 4066, 465, 2131, 2336, 4147, 2329, 1498, 3110, 4413, 1603, 4015, 110, 722, 1893, 3969, 853, 2727, 1759, 2293, 546, 4277, 586, 2397, 3157, 3831, 3159, 3975, 2649, 1803, 2386, 3622, 2081, 3117, 2405, 147, 2667, 2403, 1691, 1211, 2815, 3613, 1361, 1829, 1641, 4063, 682, 3442, 942, 3507, 3097, 2233, 2532, 3980, 3493, 464, 3865, 1938, 1928, 2733, 3112, 3433, 4145, 4466, 4284, 2609, 3757, 4429, 699, 2236, 3219, 2693, 2300, 3343, 4010, 173, 4341, 1563, 2685, 3277, 3287, 1987, 4163, 4101, 278, 4265, 834, 822, 2847, 410, 1489, 1582, 2621, 763, 2124, 3128, 1326, 325, 1563, 4542, 4545, 4077, 14, 3066, 1630, 4442, 4354, 497, 3983, 4581, 2168, 1523, 484, 2381, 441, 3770, 3113, 3297, 960, 3899, 1173, 394, 2582, 2712, 1262, 3424, 575, 3255, 274, 338, 245, 2717, 817, 1903, 2559, 3228, 1622, 3382, 2439, 3563, 3367, 2617, 180, 1315, 750, 3012, 2703, 1015, 3489, 2511, 3635, 1424, 2537, 2472, 240, 3462, 4149, 819, 3586, 3072, 4053, 1734, 2213, 1281, 1743, 2751, 2546, 949, 2918, 2817, 2105, 808, 1469, 407, 1197, 54, 379, 1785, 913, 3124, 2119, 1206, 2291, 4015, 2460, 3363, 2396, 4069, 2614, 2722, 44, 967, 4026, 3324, 266, 3382, 1314, 3366, 2875, 1540, 1305, 2015, 97, 1596, 763, 1519, 3532, 1276, 1694, 4565, 2292, 2047, 1430, 1970, 553, 3739, 3090, 1497, 2285, 2212, 25, 3429, 4154, 2088, 88, 3951, 1188, 1944, 2965, 4196, 1635, 3234, 3690, 3677, 35, 3024, 2078, 1688, 410, 2885, 1557, 4336, 1291, 4017, 2065, 3114, 3277, 1810, 2965, 3760, 119, 2086, 2964, 2032, 3185, 3653, 405, 4268, 1570, 2119, 987, 4417, 1854, 3031, 314, 3136, 3524, 798, 3098, 3042, 3202, 3821, 756, 4261, 1936, 1375, 3074, 4066, 1654, 1206, 2943, 3677, 1164, 3511, 7, 2240, 477, 4152, 3441, 3230, 3676, 847, 567, 4141, 2379, 3724, 2901, 1268, 3809, 553, 4449, 2934, 1285, 1437, 3138, 1766, 2902, 3083, 2550, 1522, 4351, 883, 174, 3621, 2422, 840, 3887, 731, 2256, 353, 3069, 3850, 2519, 750, 3624, 3376, 464, 4017, 1315, 3549, 3717, 2199, 4419, 4169, 2236, 1309, 132, 2583, 2623, 2207, 3757, 227, 4257, 1255, 2834, 2797, 1732, 501, 4314, 2329, 99, 2222, 1738, 25, 1828, 4048, 1302, 3432, 603, 3343, 2114, 693, 4179, 2293, 1445, 2559, 899, 4361, 965, 3144, 4272, 3062, 533, 224, 2394, 3346, 3931, 354, 520, 4248, 2878, 2320, 3183, 472, 1460, 1440, 202, 745, 1778, 2775, 4018, 2699, 4589, 4494, 3088, 1163, 3346, 3697, 3646, 2407, 3207, 3856, 1339, 3160, 2581, 2970, 116, 4358, 3283, 1555, 2623, 2479, 0, 115, 777, 1080, 164, 3129, 2478, 1744, 904, 458, 2236, 1515, 2673, 18, 2639, 2262, 244, 931, 4355, 2628, 2766, 4361, 1942, 843, 3101, 1201, 3416, 2646, 338, 220, 3123, 3398, 1910, 2430, 4477, 989, 4421, 200, 1399, 3967, 416, 1835, 2058, 3097, 1656]
B = [0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, -1, -1, 0, 1, 1, 0, 1, 0, 0, -1, 0, 0, -1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 1, 1, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, -1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 1, 0, 0, -1, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, -1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 1, -1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, -1, 1, 1, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, -1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, -1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, -1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, -1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, -1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, -1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, -1, 1, 0, 0, 0, 0, 0, -1, 0, 0, 1, 1, 0, 0, 0, -1, 0, -1, -1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 1, -1, 1, 0, 0, 0, 0, 0, -1, 1, 0, 1, 0, 0, 0, 1, 1, 0, 0, -1, 1, -1, 1, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 0, -1, -1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, -1, 1, 0, 1, 0, 0, -1, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 1, -1, 0, -1, 0, -1, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, -1, 0, 0, 1, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 1, 1, 0, -1, 0, 0, 0, 1, -1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1]
result = [4245, 3406, 3907, 1794, 532, 196, 1794, 2443, 3723, 2425, 3314, 954, 2216, 4023, 810, 3703, 3889, 2134, 2594, 846, 3614, 1261, 3615, 4264, 2249, 3172, 1752, 4473, 3531, 1466, 2596, 538, 3569, 3731, 65, 1049, 2797, 4567, 3395, 2222, 568, 4463, 3990, 1801, 598, 1880, 2145, 1767, 245, 561, 2705, 4032, 1081, 2397, 2963, 435, 3517, 763, 4169, 2883, 2770, 2377, 2338, 1495, 858, 1525, 37, 2010, 671, 1508, 3638, 3711, 1643, 4309, 987, 4031, 2460, 3770, 920, 651, 354, 4392, 242, 2464, 3792, 3723, 2579, 2737, 3193, 2065, 3583, 743, 4142, 2286, 978, 2190, 1262, 183, 3213, 4510, 4391, 4275, 1599, 3266, 1817, 902, 342, 242, 1089, 506, 3147, 3733, 2562, 2293, 639, 1546, 1176, 2105, 1228, 2419, 2474, 4430, 2175, 916, 2688, 1737, 2181, 945, 1206, 215, 891, 2942, 1317, 17, 325, 1661, 3998, 4242, 1666, 3929, 4187, 2232, 3869, 556, 2993, 4418, 2211, 4295, 3446, 3553, 4486, 1045, 4363, 1415, 973, 3303, 3, 3981, 2930, 3229, 605, 4157, 2406, 4511, 2724, 3886, 1231, 1053, 3420, 1771, 1725, 2161, 967, 2304, 856, 3099, 564, 1171, 2611, 1290, 1964, 3680, 1271, 1793, 2648, 346, 3332, 2074, 1559, 4370, 1019, 3155, 3307, 3932, 3954, 858, 3346, 1038, 4077, 3524, 4354, 3016, 2043, 330, 2371, 3917, 946, 735, 2466, 4158, 4388, 4378, 1209, 3261, 1157, 4193, 1497, 2010, 3684, 4425, 4130, 2691, 3908, 1064, 692, 2548, 1277, 2615, 1879, 4201, 939, 210, 1452, 4037, 253, 1454, 2121, 976, 4406, 264, 4171, 4259, 3933, 2854, 2799, 4026, 413, 2242, 921, 655, 1061, 2139, 2551, 2982, 428, 370, 1451, 2969, 183, 1291, 4309, 4140, 1581, 3419, 2426, 501, 4246, 4, 4448, 1773, 3618, 1170, 3059, 1916, 1791, 1438, 2717, 2896, 3931, 3802, 1431, 2119, 946, 488, 2800, 4245, 3244, 4049, 3030, 2559, 3381, 4282, 2534, 3896, 2685, 1268, 3472, 538, 2212, 3880, 1665, 3070, 675, 319, 4232, 3382, 4264, 4073, 3697, 2324, 622, 612, 1713, 2554, 3039, 1866, 2851, 666, 192, 2976, 3069, 2584, 2252, 590, 3035, 2603, 1373, 4513, 3215, 3439, 3928, 2190, 3476, 2224, 996, 2504, 3356, 2443, 929, 985, 1034, 2187, 2391, 3625, 4057, 3973, 371, 241, 2302, 1689, 533, 2082, 2111, 2700, 3518, 2602, 774, 1099, 3765, 2722, 1559, 146, 413, 3041, 1569, 1201, 3533, 165, 2715, 1441, 3964, 2406, 2357, 1214, 2295, 2001, 397, 751, 1307, 1756, 1585, 2047, 3555, 2304, 277, 3713, 667, 3234, 1438, 3022, 2241, 2703, 2163, 2961, 21, 1387, 2651, 3378, 3694, 4562, 577, 1491, 4234, 1231, 1321, 924, 111, 3703, 2579, 2778, 3917, 931, 4111, 4201, 4358, 741, 3925, 3624, 646, 1281, 1307, 2326, 960, 556, 2992, 2209, 3873, 1629, 3297, 3575, 2837, 3591, 1487, 4144, 625, 1553, 909, 4150, 4126, 4193, 1603, 238, 4275, 4056, 561, 4165, 96, 3792, 4255, 1343, 3443, 3048, 2927, 3981, 2977, 3107, 3562, 1153, 967, 4417, 1283, 875, 3159, 2434, 608, 4089, 179, 1101, 556, 3205, 1478, 2161, 1154, 1793, 2204, 3735, 4205, 2293, 254, 3631, 4127, 32, 1869, 861, 1181, 4268, 4342, 2692, 4209, 3907, 2983, 3979, 836, 1041, 3789, 4464, 2926, 4261, 3666, 642, 4526, 2960, 770, 1564, 1448, 1048, 2972, 3720, 3006, 218, 3864, 4274, 1348, 7, 601, 3998, 795, 2376, 2495, 1506, 3733, 2851, 1207, 2207, 2050, 2924, 4493, 4037, 3230, 1381, 2975, 2339, 480, 2588, 4080, 2361, 4147, 2021, 810, 2202, 3431, 1303, 4540, 1308, 3142, 3867, 2376, 2855, 1942, 4091, 213, 829, 2826, 814, 3728, 2955, 2874, 764, 159, 2799, 4425, 3, 4107, 684, 3466, 1019, 774, 1067, 2825, 1686, 3534, 3032, 229, 222, 2668, 2028, 2715, 1838, 2476, 95, 4422, 395, 416, 3162, 1983, 3542, 478, 3354, 2203, 3827, 1638, 4587, 422, 1034, 4467, 4589, 2050, 3713, 2323, 1461, 2970, 4282, 561, 1843, 1449, 4185, 465, 3612, 1732, 4519, 760, 3541, 3884, 139, 4016, 2577, 4466, 4442, 3618, 2698, 2950, 1985, 1027, 1743, 1878, 1960, 3820, 2886, 3497, 1673, 1991, 45, 3040, 3337, 1728, 3007, 330, 76, 172, 2453, 294, 982, 1035, 1802, 1798, 3174, 2542, 3313, 4438, 1189, 1862, 3560, 3936, 3804, 1834, 4281, 789, 2631, 1675, 110, 1549, 2744, 2444, 3512, 2966, 3528, 793, 283, 77, 765, 3612, 1245, 1067, 3489, 4355, 3029, 671, 2968, 4157, 1521, 1005, 3426, 1918, 4589, 2151, 3077, 3256, 4036, 2128, 2734, 1884, 311, 1101, 143, 422, 1970, 4429, 1018, 3016, 351, 4403, 4480, 2927, 3702, 608, 3735, 1452, 1469, 1923, 232, 80, 3278, 380, 1751, 283, 3185, 4062, 1284, 2483, 3199, 1372, 3975, 2162, 3186, 1525, 1620, 1767, 518, 782, 822, 2139, 2844, 1330, 3811, 4419, 1795, 1035, 1322, 4272, 4456, 1831, 4304, 740, 1046, 1510, 3457, 4496, 3900, 803, 1777, 1808, 795, 1020, 2711, 267, 1523, 112, 4120, 1088, 3729, 1226]

"-- Zero pad polynomials A, B to size P0P1 "
A_PAD = pad(A, P0P1)
B_PAD = pad(B, P0P1)

" -- Perform Good's permutation to obtain P_0 size - P_1 polynomials each "
A_PAD_G = goods.forward(A_PAD)
B_PAD_G = goods.forward(B_PAD)

" -- Perform P_0 size - P_1 forward NTTs "
ntt.forward_iti(A_PAD_G[0])
ntt.forward_iti(A_PAD_G[1])
ntt.forward_iti(A_PAD_G[2])
A_PAD_G_F = [A_PAD_G[_] for _ in range(P_0)]

ntt.forward_iti(B_PAD_G[0])
ntt.forward_iti(B_PAD_G[1])
ntt.forward_iti(B_PAD_G[2])
B_PAD_G_F = [B_PAD_G[_] for _ in range(P_0)]

" -- Calculate 'point-wise' multiplication of the coefficients "
"""
Note that the 'smaller' polynomial multiplications are not 'normal', as we are
not actually computing the result 'point-wise'. Instead we multiply two degree 
2 polynomials and reduce the result mod (x^3 - 1). E.g.:

( [A[0][0], A[1][0], A[2][0]] * [B[0][0], B[1][0], B[2][0]] ) % (X^3 - 1)
= C[0][0], C[1][0], C[2][0]
"""

# Define variable for storing the result of the computation
C_PAD_G_F = [[0 for _ in range(P_1)] for _ in range(P_0)]

for i in range(P_1):

    # Define an accumulator to store temporary values
    accum = [0 for _ in range(2 * P_0 - 1)]

    # Obtain two degree 2 polynomials from A, B
    poly_a = [A_PAD_G_F[0][i], A_PAD_G_F[1][i], A_PAD_G_F[2][i]]
    poly_b = [B_PAD_G_F[0][i], B_PAD_G_F[1][i], B_PAD_G_F[2][i]]

    # Multiply the two polynomials naively
    for n in range(P_0):
        for m in range(P_0):
            accum[n + m] += poly_a[n] * poly_b[m]

    # Reduce mod (x^3 - 1)
    for ix in range(2 * P_0 - 2, P_0 - 1, -1):
        if accum[ix] > 0:  # x^p is nonzero
            accum[ix - P_0] += accum[ix]  # add x^p into x^0
            accum[ix] = 0  # zero x^p

    # Store the result
    C_PAD_G_F[0][i] = accum[0]
    C_PAD_G_F[1][i] = accum[1]
    C_PAD_G_F[2][i] = accum[2]

" -- Inverse P_0 size - P_1 NTTs "
ntt.inverse_iti(C_PAD_G_F[0])
ntt.inverse_iti(C_PAD_G_F[1])
ntt.inverse_iti(C_PAD_G_F[2])
C_PAD_G = [C_PAD_G_F[_] for _ in range(P_0)]

" -- Undo Good's permutation "
C_PAD = goods.inverse(C_PAD_G)

" -- Reduce mod (x^761 - x - 1) "
for i in range(P0P1 - 1, VAR_P - 1, -1):
    if C_PAD[i] > 0:  # x^p is nonzero
        C_PAD[i - VAR_P + 1] += C_PAD[i]  # add x^p into x^1
        C_PAD[i - VAR_P] += C_PAD[i]  # add x^p into x^0
        C_PAD[i] = 0  # zero x^p

C_PAD = reduce_q(C_PAD, NEW_Q)

" -- Store the result "
C = reduce_q(C_PAD, VAR_Q)[:VAR_P]

print(f"Zx({A}) * Zx({B}) % (x^{VAR_P} - x - 1) % {VAR_Q} == Zx({C})")
