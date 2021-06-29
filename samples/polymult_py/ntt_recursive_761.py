#!/usr/bin/env python3

"""
This script can be used to perform NTT based polynomial multiplication of
two polynomials for the NTRU LPRime 'kem/ntrulpr761' parameter set.

While 761 is not an NTT friendly prime and the reduction polynomial is not
of the form x^n + 1 or x^n - 1, we can use Good's permutation after padding
to size 1536 to perform 3 size 512 NTTs instead. These smaller size - 512
cyclic NTTs are used to multiply polynomials in Z_6984193 [x] / (x^512 - 1).

Please be aware that field elements are within { - (q-1)/2, ..., (q-1)/2 }
"""

from lib_common import Goods
from lib_common import NTT
from lib_common import pad
from lib_common import reduce_q

def weigh(cvec, q, q12, size):
    out = [0] * size
    for i in range(size):
        out[i] = divmod(cvec[i] + q12, q)[1] - q12
    return out

# Define the original and NTT 'suitable' parameters
VAR_Q, VAR_P, NEW_Q = 4591, 761, 6984193
P_0, P_1, P0P1 = 3, 512, 1536

# These are the roots for a size - 512 cyclic NTT, i.e. we are multiplying
# polynomials in Z_6984193 [x] / (x^512 - 1).
roots = [1, 1, 1888710, 1, 1888710, 2249918, 1189439, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 5503199, 1118760, 1516650, 1136094, 1305215, 3924598, 4044239, 6251766, 3905570, 978083, 930959, 6064175, 3894385, 2940558, 6629701, 92432, 5801064, 4976760, 5102405, 6225518, 1190023, 4238421, 923827, 1308559, 4878190, 1687037, 888587, 2527449, 1082755, 3564685, 2493111, 6787824, 1355126, 5676487, 862290, 6701195, 1866623, 647018, 6767961, 1144955, 3519122, 2849661, 774651, 435412, 231691, 2496195, 6538397, 23955, 683141, 2407483, 6863121, 6550086, 1450505, 5657528, 6461287, 2972484, 4167428, 3142354, 1373895, 3110809, 2777653, 4425680, 665089, 4244789, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 5503199, 1118760, 1516650, 1136094, 1305215, 3924598, 4044239, 6251766, 3905570, 978083, 930959, 6064175, 3894385, 2940558, 6629701, 92432, 5801064, 4976760, 5102405, 6225518, 1190023, 4238421, 923827, 1308559, 4878190, 1687037, 888587, 2527449, 1082755, 3564685, 2493111, 6787824, 1355126, 5676487, 862290, 6701195, 1866623, 647018, 6767961, 1144955, 3519122, 2849661, 774651, 435412, 231691, 2496195, 6538397, 23955, 683141, 2407483, 6863121, 6550086, 1450505, 5657528, 6461287, 2972484, 4167428, 3142354, 1373895, 3110809, 2777653, 4425680, 665089, 4244789, 6358, 2590413, 1351380, 5556336, 6763602, 2621612, 6045621, 2624175, 5914879, 2029063, 4083230, 628191, 4991048, 149857, 4813523, 4044651, 440308, 6262170, 4991238, 2810914, 6352749, 6199440, 6365889, 2026918, 5214196, 882352, 3817389, 4692044, 3272569, 6801306, 3255215, 6945715, 2608026, 131613, 5050988, 2642920, 3999892, 2071852, 2992250, 2253181, 6435502, 3362923, 2228956, 3440536, 2688039, 4500902, 3181154, 6611809, 5282741, 3507854, 6481066, 1319217, 3556037, 1380592, 474465, 5938899, 2940212, 6110290, 3850420, 875985, 1833815, 6593827, 409841, 5700727, 5516505, 3167606, 4674360, 1630090, 1335686, 5056688, 4457129, 1685865, 2807945, 2719944, 3425851, 3279290, 1535645, 6367296, 2034203, 1010444, 6625872, 3845790, 6498698, 2421713, 2285215, 2864124, 6969946, 1644259, 5715100, 5444991, 6408202, 5876842, 4726185, 560945, 4065821, 1656445, 4381139, 3779115, 6832508, 2620510, 1845127, 50767, 1082965, 2094784, 4207497, 1147996, 1374993, 2609068, 6410848, 2721314, 1211390, 5637837, 6226625, 4410051, 5469647, 5688122, 3176030, 1969074, 6823713, 6811207, 5463175, 4294752, 4983160, 6273239, 4277870, 6144036, 3199097, 1446710]
roots_inv = [1, 1, 5095483, 1, 5095483, 5794754, 4734275, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 2739404, 6319104, 2558513, 4206540, 3873384, 5610298, 3841839, 2816765, 4011709, 522906, 1326665, 5533688, 434107, 121072, 4576710, 6301052, 6960238, 445796, 4487998, 6752502, 6548781, 6209542, 4134532, 3465071, 5839238, 216232, 6337175, 5117570, 282998, 6121903, 1307706, 5629067, 196369, 4491082, 3419508, 5901438, 4456744, 6095606, 5297156, 2106003, 5675634, 6060366, 2745772, 5794170, 758675, 1881788, 2007433, 1183129, 6891761, 354492, 4043635, 3089808, 920018, 6053234, 6006110, 3078623, 732427, 2939954, 3059595, 5678978, 5848099, 5467543, 5865433, 1480994, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 2739404, 6319104, 2558513, 4206540, 3873384, 5610298, 3841839, 2816765, 4011709, 522906, 1326665, 5533688, 434107, 121072, 4576710, 6301052, 6960238, 445796, 4487998, 6752502, 6548781, 6209542, 4134532, 3465071, 5839238, 216232, 6337175, 5117570, 282998, 6121903, 1307706, 5629067, 196369, 4491082, 3419508, 5901438, 4456744, 6095606, 5297156, 2106003, 5675634, 6060366, 2745772, 5794170, 758675, 1881788, 2007433, 1183129, 6891761, 354492, 4043635, 3089808, 920018, 6053234, 6006110, 3078623, 732427, 2939954, 3059595, 5678978, 5848099, 5467543, 5865433, 1480994, 5537483, 3785096, 840157, 2706323, 710954, 2001033, 2689441, 1521018, 172986, 160480, 5015119, 3808163, 1296071, 1514546, 2574142, 757568, 1346356, 5772803, 4262879, 573345, 4375125, 5609200, 5836197, 2776696, 4889409, 5901228, 6933426, 5139066, 4363683, 151685, 3205078, 2603054, 5327748, 2918372, 6423248, 2258008, 1107351, 575991, 1539202, 1269093, 5339934, 14247, 4120069, 4698978, 4562480, 485495, 3138403, 358321, 5973749, 4949990, 616897, 5448548, 3704903, 3558342, 4264249, 4176248, 5298328, 2527064, 1927505, 5648507, 5354103, 2309833, 3816587, 1467688, 1283466, 6574352, 390366, 5150378, 6108208, 3133773, 873903, 4043981, 1045294, 6509728, 5603601, 3428156, 5664976, 503127, 3476339, 1701452, 372384, 3803039, 2483291, 4296154, 3543657, 4755237, 3621270, 548691, 4731012, 3991943, 4912341, 2984301, 4341273, 1933205, 6852580, 4376167, 38478, 3728978, 182887, 3711624, 2292149, 3166804, 6101841, 1769997, 4957275, 618304, 784753, 631444, 4173279, 1992955, 722023, 6543885, 2939542, 2170670, 6834336, 1993145, 6356002, 2900963, 4955130, 1069314, 4360018, 938572, 4362581, 220591, 1427857, 5632813, 4393780, 6977835]

# Define objects to interact with the implemented Good's and NTT methods
goods = Goods(P_0, P_1, P0P1)
ntt = NTT(NEW_Q, P_1, roots, roots_inv)

# Define two polynomials A, B
# *. A is a polynomial with integer coefficients in Z_q
# *. B is a polynomial with integer coefficients in {-1, 0, 1}
A = [-1495, -1846, 630, -1590, -211, 2037, 1307, -2213, 1158, -957, -906, 454, -2134, 845, 1576, -998, -1325, 748, 685, 1434, -2174, 376, -1520, -1817, 1866, -1045, -772, 22, -777, -1515, 1132, -1722, -1445, 1390, -279, 1700, -762, -1892, -1959, -1792, -1204, -1773, -351, -499, 834, -867, 552, -1639, 1663, -2148, 676, 558, 1461, 442, -2006, 1034, 2035, -1149, 422, -1802, 294, -1044, -350, 1023, -1741, -1151, 1532, -1794, 1929, 2080, -2246, -771, -703, -2100, 2033, 1956, -2228, -911, 2247, -1346, 1261, 1041, 724, -817, -1466, 929, 1175, 740, -795, 1321, -1013, 1261, -1711, 1929, 1421, -681, 18, -799, -2230, 2103, 1510, -578, 1078, 1330, 1503, -1816, 1011, -790, 196, -510, -510, 782, 912, 759, 2027, -711, -6, -1923, -1166, 1424, -103, 758, -495, 299, -824, 222, -1648, 1879, -747, -819, -344, 1496, 1179, 2191, -30, 1734, -1784, 82, 1587, -602, -1600, 339, -747, -1250, -96, -405, 1863, -2187, 656, 1930, -2272, 477, 1745, -1712, 11, 148, 1836, 1670, 1175, 1759, -470, -146, -1245, 1758, 987, -2197, 1394, -134, -1716, 308, 1599, -421, -1864, 1444, -2131, -974, -2222, 16, 58, -347, -1528, -1731, 341, 1387, -1094, 1757, 1162, 1784, -1055, -1963, 1238, 1699, 2127, -792, 2007, -248, 383, -1355, 1124, -889, -1458, -1251, 1779, -453, 1988, 890, -2038, -589, 794, -941, -1526, 1383, -1161, 1793, -43, -1775, 849, -1170, -1254, -419, 160, -1678, 2038, 1390, -46, -1473, 435, 1233, -1531, 2129, 231, 568, 1697, -1274, -276, 1867, 2181, -1440, 91, 1256, 398, -2113, -910, -1878, 250, 2166, 430, 1397, -1495, 830, -1370, -2087, 1603, -2105, 1169, -1150, -768, -2138, 1860, 1556, -1515, -448, 1783, 362, 1178, 1366, -1799, 1241, -319, 1837, -614, -562, -383, -589, -239, -101, -460, 1647, -1443, -277, -756, -809, -1996, -1955, 2178, 1639, -987, 1162, 437, 1396, -1800, -627, -1044, -568, -452, 1156, 35, 1750, 2249, -1839, -744, 929, 39, 658, 634, -2177, -693, -782, 67, 341, 684, 279, -2209, 1883, 1897, -196, -1636, 1581, 2254, 491, 1746, -1204, -1909, 2235, 58, -23, 1871, 593, -844, -1318, 1349, 1926, 871, -2004, -1915, 465, 1487, -243, -1155, -1445, -190, 276, 1599, 724, -2032, 2157, -1763, -1954, -451, 1948, 1776, -1687, 1124, -1042, 1651, -841, 597, -394, -1883, 1952, 244, -439, 655, 361, 1726, -1142, 1218, -32, 951, -860, 334, -2176, -1259, 1106, 1318, 405, 1223, 879, 629, -1657, 1827, 1271, -1141, -1549, 1428, 2240, 183, 1485, -448, 226, 1880, 105, -1603, 2283, 1615, 560, 1784, 2054, 2169, 143, 2228, -2148, 585, 1254, 1985, 2073, 466, -1236, 464, -2222, 2059, -1381, 253, -776, -1962, -1514, -2259, 639, 355, 323, 749, -606, -2090, 94, 1369, 1580, 1606, 921, 1631, 2200, 825, 201, -897, -1246, -1039, 569, -1843, -774, -528, 413, -1801, 1312, 802, 314, -1183, 1834, 1152, -917, -1675, -132, -425, 1855, 1410, -1597, 2137, -905, -626, -2263, 684, 2244, -1695, -260, -138, 1127, 1728, -1112, 1683, -1719, -2083, -1883, 1827, -2072, -1418, 622, -2267, -1897, -893, -1787, 689, -406, -1985, -2097, 1940, -809, 461, 1680, -1961, 594, 1410, -2101, -111, -1442, -1659, 2290, -1791, -146, -1226, -1546, -2164, -1706, 444, -1547, -858, -1316, 1636, -1747, -1414, -1415, -1980, -349, 1141, 2107, -461, 1059, 1495, -1882, -1276, -1610, 1586, -1113, 1578, -1570, -1765, 238, -1774, -692, -1038, -475, -1039, 1541, 1004, 2294, 159, 2144, -733, -1621, -2054, 196, -744, 2152, -1107, -1038, -856, -1423, -875, -1156, 1693, -394, -1355, -1960, -334, 576, 957, 1010, 1867, 378, 2167, 221, 2090, 1813, 1801, 1445, -1542, 585, 1854, 1796, -461, 216, -1395, 23, -1198, -1661, -397, 2068, -461, -755, 5, -2093, 974, 847, 1132, -2109, -429, -1576, -2055, 728, -605, 418, -1322, -240, 651, 1429, 1635, -1960, 1669, 2136, 1293, 787, 501, 1326, 603, 650, -339, 156, -917, 1580, -1786, 512, 1625, -94, -436, 117, -1084, 2280, -1464, 130, -735, 1456, 190, 1569, 585, 956, -1423, 44, -73, 1089, 2169, 1202, 2044, -1434, -2123, 874, -1272, -1184, -2043, -156, -1493, -2251, 1894, 340, 16, 1315, 991, -111, 2024, -990, -1470, 607, 873, -656, 1784, 576, 1851, 178, -2267, 13, 1793, 1886, -875, 1929, -920, 1221, -1420, 2110, -1391, -79, -666, 345, 1563, -2035, -2121, 1976, 447, -1292, 2076, 683, 1674, 758, 2006, -1934, 929, 553, -1704, 1761, -1307, 940, -1632, -524, -1025, -1756, -1943, 100, -1882, -958, 1276, -662, 1986, 944, -231, 1187, 167, 497, 1535, -135, 789, -323, -44, -577, -911, -1962, -1961, 867, 1805, -532, 955, 752, -1578, -239, 427, 1725, 2185, 1838, 367, 1430, -2070, 1600, 1170, -1038, 2127, 803, 389, 478, 50, -1052, 1938, 1130, -1323, -397, 463, -471, 1155, -2009, 472, -592, -1225, 2007, 220, 2204, -1306, 1035, -2109, 1608, 843, 41, -1445, -1933, 602, 319, 805, -1619, 99]
B = [0, 0, 0, 0, -1, -1, 0, -1, 0, 0, 0, -1, 0, -1, 0, 0, 1, 0, -1, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, -1, 0, 1, 0, -1, 0, 0, -1, 0, -1, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, -1, 1, 0, 0, 0, 0, 1, 0, 0, -1, 1, 0, 1, 0, 0, 0, -1, 0, 0, -1, 0, 1, 1, 0, 1, 0, -1, 0, 0, -1, -1, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 1, 0, -1, 0, 0, -1, -1, -1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 1, 0, 0, -1, 0, 0, 0, -1, 0, 0, 0, 0, 1, -1, 1, 0, 0, -1, 1, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, -1, 0, 0, 0, 1, 0, 1, 0, 0, -1, 0, 0, -1, 0, -1, 0, 1, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, -1, 0, 1, 1, -1, -1, 0, 1, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, -1, -1, 1, 0, 0, 1, 0, -1, 0, 1, 0, 0, 1, 1, 0, 1, -1, -1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, -1, 1, -1, 0, -1, -1, -1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, -1, 0, 0, 1, -1, 0, 0, -1, 0, -1, 0, 0, 0, -1, 0, 0, 0, 0, 1, 1, 0, 1, 0, -1, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, -1, 1, 0, 1, 0, 0, 0, -1, 0, 1, -1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, -1, 1, 1, -1, -1, 0, -1, 0, 1, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, -1, -1, -1, 0, 0, -1, -1, 1, 1, -1, -1, 0, 0, 0, 0, 0, 0, -1, 0, 1, 1, 1, 0, -1, 0, -1, 0, -1, 0, 0, 0, 0, 1, -1, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, -1, 0, 0, 0, -1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 1, -1, 0, -1, -1, 0, 0, 0, -1, 0, -1, 1, 0, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1, 1, 0, 0, -1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, -1, 0, 0, 0, 0, 0, -1, 0, 0, -1, 0, 1, 1, -1, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, 1, -1, 1, 0, 0, 0, -1, 1, 0, 0, 0, 1, 0, 0, -1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 1, 0, -1, 0, -1, 0, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 1, 1, 0, 1, -1, 0, -1, 0, -1, 0, 0, 0, 0, 1, 0, 0, 0, 0, -1, -1, 0, 0, 1, 0, 0, 1, 0, 1, 0, 0, 0, -1, 0, 0, 0, -1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, -1, -1, -1, 0, 0, 0, 1, -1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, -1, 0, 0, 0, 0, 0, 0, -1, 0, 0, -1, 0, 0, 0, 0, -1, -1, 1, 0, -1, 0, 0, -1, 0, 0, 0, 0, -1, 0, 0, -1, -1, -1, 0, 0, 0, 0, 0, 0, 1, 0]
result = [-2205, -614, -709, 1379, 1873, -243, -2180, 1550, 315, -592, 1357, -1708, -711, 1047, -2291, -2037, -373, 976, 2145, 328, 1583, 1816, -35, -760, 1490, 1572, 1368, 1901, -1180, -1313, -1629, -246, 1239, 933, 857, -2057, 402, -865, -525, -313, 140, -2105, 811, -43, 374, -1487, -1502, -1367, 1153, -1182, -418, -1703, 1331, -638, 779, -2163, 899, 1043, 2131, 552, 1137, -928, 1401, 1990, 1572, -267, -855, -1636, -1792, -2253, -1553, 459, -168, -1493, 1845, 251, -322, -1453, -1216, 1832, 477, -1470, -105, -145, 189, -1576, -2289, 1844, 559, 336, 1150, 352, -1691, 1094, -1723, -776, 1299, 1469, 1488, -1751, 1009, 1351, -2026, -1172, -2292, -2162, -278, -517, -798, -1707, 312, -924, -263, 2184, -2100, -350, 407, 400, -1662, -1139, -1909, -2133, 1549, -28, 1710, 107, -1407, 1231, 2030, 1102, -553, -1130, -230, -8, 1582, -1881, 1072, 2132, -1835, -879, 124, 1950, 1057, -1249, 182, -1370, 1079, -877, 835, 2268, 1656, -1984, 1789, 374, -616, -715, -1316, -699, -1951, 1619, -2039, -1341, -397, -1776, -2186, -1280, -532, 2058, 1984, -1248, -1088, 2026, -224, 1234, 1990, 1249, 177, -1702, -2025, -1698, 1150, 1807, -104, 1987, -134, 774, -977, -1882, -812, -9, 382, 67, 1124, -885, -1991, 1224, -408, -2073, 1068, -28, -1090, -525, -1318, 1833, -1463, -326, -2287, 65, 1625, -1764, 2247, 175, 1632, -2095, 160, -483, -1719, 1267, -683, 591, 304, -989, 1148, -1686, -1238, -1612, -688, 2180, -419, -1070, -1451, -1470, 635, -494, 184, -1856, 895, -144, 1912, -1743, 2261, 1457, 1906, 51, -1818, -17, -557, -2243, -1560, -1852, 53, -1784, 1684, 1110, -645, 566, -883, 2036, 446, 221, 504, 2208, -789, 1400, 1635, -2004, -1953, 277, -1041, -405, 13, -844, -961, 186, 849, -1975, 890, -234, 2174, 587, -852, 1389, 1529, -1205, -841, 912, 1792, 615, 2074, 1762, 1132, 1866, 2153, -707, -2276, -2238, 76, -170, 1478, -1538, 505, 287, -1712, -1337, -1336, 1334, -584, -1869, -905, 1959, 1144, 1547, 1333, -117, 191, 1012, -1137, 1806, -1632, 435, -1939, -1049, 957, -160, -296, -985, -492, 1086, -1328, -2288, 838, -386, 1370, 1569, 1446, -1372, -1283, -60, 1051, -862, 481, 2251, 294, -1017, 1449, 1537, 1395, 475, -1461, -786, -740, -1581, -1520, 522, 273, -1442, -1368, 1227, -1056, -2130, 1775, 1872, -1355, -475, -1632, 263, -1748, -838, 729, 880, -174, -1109, 1682, -1286, -1399, -1069, -1369, -939, -1591, 1632, -278, -2263, 1290, 645, -570, -737, -955, -886, -1653, 1361, 827, 987, 212, 5, 1111, -247, 1021, 1167, -662, -1515, 1887, 2143, 1581, -2118, -915, 799, 662, 1191, 1091, 1584, -837, -325, 11, -499, -552, 870, -1319, 1415, 593, -1106, -677, 1056, -1423, 25, -451, -2086, -1503, 672, -2185, 1499, 2110, -411, -696, -2022, 977, -403, 889, 527, -829, 165, -2115, 2087, 1018, -1681, 1297, 1557, -2079, 1260, 1042, 607, 1430, -531, -1760, -2249, -2001, -2012, 2208, -1475, 1535, -346, -1067, -67, -1241, -1968, -1230, 866, 1145, -1152, 1308, 520, -1909, -2085, -572, -1685, -443, 1302, -1924, -1245, 1143, -617, 384, 74, -484, 1025, 1832, -1752, -291, -179, 1999, -591, 1749, 1093, -691, 875, 1256, -80, 149, -554, -1435, 45, 1070, -1472, 922, 194, 2226, 1543, -2122, -1288, -158, -2234, 2057, 1163, -1873, -2189, 547, 548, -497, -308, 2221, 760, -248, 2009, -314, -1572, 397, -250, 1470, 1393, 769, 66, 1390, 613, -175, 755, -245, -61, 600, -1097, -945, -2, 471, -1374, 1457, 1215, 1916, 306, 16, 1264, -2051, 94, -1506, -1836, 762, -1562, -1325, 1432, -332, 383, 1889, -1558, 1398, -916, -733, 620, -107, -1613, -1448, -838, 519, -1040, -343, -846, -1856, 1494, 718, -846, -756, -807, 2166, -1197, -1212, -1948, -69, 1956, 1440, 1417, -443, -691, 644, -328, 1260, 512, 761, -530, -309, 36, -24, -1245, -2126, 434, 425, -1520, -2139, -1751, -16, -1758, 1975, -1033, -1024, -1606, 2160, -660, -1735, -688, -47, -1340, 1867, 887, 1514, 1615, -601, 221, 2282, -719, 1781, 96, 1136, -389, 1742, -1969, -2230, 1754, 623, 2117, 301, -466, -1371, 1883, -1039, 2056, -1878, -367, 917, -583, 2144, -2070, -492, 127, -1562, 2159, 1350, -686, -1015, 946, -1906, 1096, 446, -550, 159, 1649, -1820, -280, -1901, -1509, 951, -372, -2130, -1847, -1429, -1349, -1560, -1700, -2051, 1480, -1844, -63, -2215, -2223, -1973, -444, 1551, -749, 2246, 1137, -97, 839, -1970, 1149, 735, 1620, -1845, 2222, -95, 1432, 1683, 672, 2234, 600, -1228, -262, -1081, 553, 744, -1807, -408, -997, -1838, -1265, 1930, 1012, -1933, -1028, -99, 1537, 1015, 941, 78, 1931, -2147, 703, 1110, 1494, 786, -1014, 2028, 1169, 1008, 383, -1352, -2063, -743, -828, -1852, -1976, -1501, -1246, -581, -2176, -1201, -1325, 1340, -515, -831, -684, -1694, 1565, 514, 470, -1829, 1499, -1317, -2227, 337, 106, 638, -308, 1990, -1472, -842, 711, -458]

"-- Zero pad polynomials A, B to size P0P1 "
A_PAD = pad(A, P0P1)
B_PAD = pad(B, P0P1)

" -- Perform Good's permutation to obtain P_0 size - P_1 polynomials each "
A_PAD_G = goods.forward(A_PAD)
B_PAD_G = goods.forward(B_PAD)

" -- Perform P_0 size - P_1 forward NTTs "
A_PAD_G_F = [ntt.forward_rec(A_PAD_G[_]) for _ in range(P_0)]
B_PAD_G_F = [ntt.forward_rec(B_PAD_G[_]) for _ in range(P_0)]

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
C_PAD_G = [ntt.inverse_rec(C_PAD_G_F[_]) for _ in range(P_0)]

" -- Undo Good's permutation "
C_PAD = goods.inverse(C_PAD_G)

" -- Reduce mod (x^761 - x - 1) "
for i in range(P0P1 - 1, VAR_P - 1, -1):
    if C_PAD[i] > 0:  # x^p is nonzero
        C_PAD[i - VAR_P + 1] += C_PAD[i]  # add x^p into x^1
        C_PAD[i - VAR_P] += C_PAD[i]  # add x^p into x^0
        C_PAD[i] = 0  # zero x^p

C_PAD = reduce_q(C_PAD, NEW_Q)[:VAR_P]

# We need to ensure that the result in the integer domain is correct (i.e. the
# coefficients are in {-q'/2, ..., +q'/2}) before reducing mod q.
C = weigh(C_PAD, 6984193, 3492096, 761)

# Ensure that the result is in in { - (q-1)/2, ..., (q-1)/2 }
C = weigh(C, 4591, 2295, 761)

print(f"The result is: {C == result}")

counter = 0
for i in range(761):
    if C[i] != result[i]:
        counter += 1
print(f"There are {counter} incorrect results")

# print(f"Zx({A}) * Zx({B}) % (x^{VAR_P} - x - 1) % {VAR_Q} == Zx({C})")
