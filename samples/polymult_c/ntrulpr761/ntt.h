#ifndef NTT_H
#define NTT_H

/**
 * This header accompanies ntt.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <stddef.h>
#include <stdint.h>

/* Include user header files */

#include "params.h"
#include "util.h"

/**
 * Define the (inverse) roots used in the NTT transformations
 *
 * These are the roots for a size - 512 cyclic NTT, i.e. we are multiplying
 * polynomials in Z_6984193 [x] / (x^512 - 1). Remember that the inverse roots
 * have been reordered.
 *
 * const int32_t roots[NTT_P - 1] = {1, 1, 1888710, 1, 1888710, 2249918, 1189439, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 5503199, 1118760, 1516650, 1136094, 1305215, 3924598, 4044239, 6251766, 3905570, 978083, 930959, 6064175, 3894385, 2940558, 6629701, 92432, 5801064, 4976760, 5102405, 6225518, 1190023, 4238421, 923827, 1308559, 4878190, 1687037, 888587, 2527449, 1082755, 3564685, 2493111, 6787824, 1355126, 5676487, 862290, 6701195, 1866623, 647018, 6767961, 1144955, 3519122, 2849661, 774651, 435412, 231691, 2496195, 6538397, 23955, 683141, 2407483, 6863121, 6550086, 1450505, 5657528, 6461287, 2972484, 4167428, 3142354, 1373895, 3110809, 2777653, 4425680, 665089, 4244789, 1, 1888710, 2249918, 1189439, 2474861, 4822779, 2631832, 5511532, 2475826, 4553556, 1718679, 928322, 1896777, 3698636, 6344531, 3657506, 2320078, 1989250, 6389597, 3902275, 4857419, 1503708, 6061365, 6764814, 1806736, 476883, 4980051, 995969, 421236, 2268351, 5436934, 2489170, 6305737, 4210529, 1839665, 6554001, 6497093, 2181925, 3555181, 4977608, 1317002, 542084, 4846884, 1909715, 6713289, 2885340, 5721431, 5929585, 5626193, 6857320, 236096, 4089882, 2275530, 2309241, 212083, 5845994, 4833814, 5592270, 4550547, 6513079, 3085944, 4549880, 1991625, 6498459, 5503199, 1118760, 1516650, 1136094, 1305215, 3924598, 4044239, 6251766, 3905570, 978083, 930959, 6064175, 3894385, 2940558, 6629701, 92432, 5801064, 4976760, 5102405, 6225518, 1190023, 4238421, 923827, 1308559, 4878190, 1687037, 888587, 2527449, 1082755, 3564685, 2493111, 6787824, 1355126, 5676487, 862290, 6701195, 1866623, 647018, 6767961, 1144955, 3519122, 2849661, 774651, 435412, 231691, 2496195, 6538397, 23955, 683141, 2407483, 6863121, 6550086, 1450505, 5657528, 6461287, 2972484, 4167428, 3142354, 1373895, 3110809, 2777653, 4425680, 665089, 4244789, 6358, 2590413, 1351380, 5556336, 6763602, 2621612, 6045621, 2624175, 5914879, 2029063, 4083230, 628191, 4991048, 149857, 4813523, 4044651, 440308, 6262170, 4991238, 2810914, 6352749, 6199440, 6365889, 2026918, 5214196, 882352, 3817389, 4692044, 3272569, 6801306, 3255215, 6945715, 2608026, 131613, 5050988, 2642920, 3999892, 2071852, 2992250, 2253181, 6435502, 3362923, 2228956, 3440536, 2688039, 4500902, 3181154, 6611809, 5282741, 3507854, 6481066, 1319217, 3556037, 1380592, 474465, 5938899, 2940212, 6110290, 3850420, 875985, 1833815, 6593827, 409841, 5700727, 5516505, 3167606, 4674360, 1630090, 1335686, 5056688, 4457129, 1685865, 2807945, 2719944, 3425851, 3279290, 1535645, 6367296, 2034203, 1010444, 6625872, 3845790, 6498698, 2421713, 2285215, 2864124, 6969946, 1644259, 5715100, 5444991, 6408202, 5876842, 4726185, 560945, 4065821, 1656445, 4381139, 3779115, 6832508, 2620510, 1845127, 50767, 1082965, 2094784, 4207497, 1147996, 1374993, 2609068, 6410848, 2721314, 1211390, 5637837, 6226625, 4410051, 5469647, 5688122, 3176030, 1969074, 6823713, 6811207, 5463175, 4294752, 4983160, 6273239, 4277870, 6144036, 3199097, 1446710};
 * const int32_t roots_inv[NTT_P - 1] = {1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 2739404, 6319104, 2558513, 4206540, 3873384, 5610298, 3841839, 2816765, 4011709, 522906, 1326665, 5533688, 434107, 121072, 4576710, 6301052, 6960238, 445796, 4487998, 6752502, 6548781, 6209542, 4134532, 3465071, 5839238, 216232, 6337175, 5117570, 282998, 6121903, 1307706, 5629067, 196369, 4491082, 3419508, 5901438, 4456744, 6095606, 5297156, 2106003, 5675634, 6060366, 2745772, 5794170, 758675, 1881788, 2007433, 1183129, 6891761, 354492, 4043635, 3089808, 920018, 6053234, 6006110, 3078623, 732427, 2939954, 3059595, 5678978, 5848099, 5467543, 5865433, 1480994, 5537483, 3785096, 840157, 2706323, 710954, 2001033, 2689441, 1521018, 172986, 160480, 5015119, 3808163, 1296071, 1514546, 2574142, 757568, 1346356, 5772803, 4262879, 573345, 4375125, 5609200, 5836197, 2776696, 4889409, 5901228, 6933426, 5139066, 4363683, 151685, 3205078, 2603054, 5327748, 2918372, 6423248, 2258008, 1107351, 575991, 1539202, 1269093, 5339934, 14247, 4120069, 4698978, 4562480, 485495, 3138403, 358321, 5973749, 4949990, 616897, 5448548, 3704903, 3558342, 4264249, 4176248, 5298328, 2527064, 1927505, 5648507, 5354103, 2309833, 3816587, 1467688, 1283466, 6574352, 390366, 5150378, 6108208, 3133773, 873903, 4043981, 1045294, 6509728, 5603601, 3428156, 5664976, 503127, 3476339, 1701452, 372384, 3803039, 2483291, 4296154, 3543657, 4755237, 3621270, 548691, 4731012, 3991943, 4912341, 2984301, 4341273, 1933205, 6852580, 4376167, 38478, 3728978, 182887, 3711624, 2292149, 3166804, 6101841, 1769997, 4957275, 618304, 784753, 631444, 4173279, 1992955, 722023, 6543885, 2939542, 2170670, 6834336, 1993145, 6356002, 2900963, 4955130, 1069314, 4360018, 938572, 4362581, 220591, 1427857, 5632813, 4393780, 6977835, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 2739404, 6319104, 2558513, 4206540, 3873384, 5610298, 3841839, 2816765, 4011709, 522906, 1326665, 5533688, 434107, 121072, 4576710, 6301052, 6960238, 445796, 4487998, 6752502, 6548781, 6209542, 4134532, 3465071, 5839238, 216232, 6337175, 5117570, 282998, 6121903, 1307706, 5629067, 196369, 4491082, 3419508, 5901438, 4456744, 6095606, 5297156, 2106003, 5675634, 6060366, 2745772, 5794170, 758675, 1881788, 2007433, 1183129, 6891761, 354492, 4043635, 3089808, 920018, 6053234, 6006110, 3078623, 732427, 2939954, 3059595, 5678978, 5848099, 5467543, 5865433, 1480994, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 485734, 4992568, 2434313, 3898249, 471114, 2433646, 1391923, 2150379, 1138199, 6772110, 4674952, 4708663, 2894311, 6748097, 126873, 1358000, 1054608, 1262762, 4098853, 270904, 5074478, 2137309, 6442109, 5667191, 2006585, 3429012, 4802268, 487100, 430192, 5144528, 2773664, 678456, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 4495023, 1547259, 4715842, 6562957, 5988224, 2004142, 6507310, 5177457, 219379, 922828, 5480485, 2126774, 3081918, 594596, 4994943, 4664115, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 3326687, 639662, 3285557, 5087416, 6055871, 5265514, 2430637, 4508367, 1, 5095483, 5794754, 4734275, 1472661, 4352361, 2161414, 4509332, 1, 5095483, 5794754, 4734275, 1, 5095483, 1};
 *
 * Since we are performing the multiplications using Montgomery modular
 * multiplication we need to ensure that one of the multiplicands is in the
 * Montgomery domain. The easiest approach to ensure this is to update our
 * roots. We can do this by multiplying each root r like this:
 *
 * r' = (r * 2^32) % NTT_Q = (r * 4294967296) % 6984193.
 *
 * This produces the following roots and roots_inv arrays.
 */

static const int32_t roots[NTT_P - 1] = {6672794, 6672794, 3471433, 6672794, 3471433, 4089706, 2592208, 6672794, 3471433, 4089706, 2592208, 1536046, 2462969, 3290424, 3050359, 6672794, 3471433, 4089706, 2592208, 1536046, 2462969, 3290424, 3050359, 1356310, 6967367, 3787669, 4189985, 5725180, 4731673, 922778, 3562581, 6672794, 3471433, 4089706, 2592208, 1536046, 2462969, 3290424, 3050359, 1356310, 6967367, 3787669, 4189985, 5725180, 4731673, 922778, 3562581, 2891570, 5553192, 5643374, 1238959, 6179794, 2052193, 3095387, 2009488, 2867644, 4006442, 1280757, 3307920, 4643762, 5078585, 3367043, 1642889, 6672794, 3471433, 4089706, 2592208, 1536046, 2462969, 3290424, 3050359, 1356310, 6967367, 3787669, 4189985, 5725180, 4731673, 922778, 3562581, 2891570, 5553192, 5643374, 1238959, 6179794, 2052193, 3095387, 2009488, 2867644, 4006442, 1280757, 3307920, 4643762, 5078585, 3367043, 1642889, 5665887, 2000205, 1605297, 4536868, 6733519, 968737, 5576790, 751477, 5691355, 3529294, 4197549, 6724279, 4151642, 3486211, 5773945, 137539, 924236, 5529719, 2541407, 3381211, 4486924, 4157314, 94891, 204037, 2397960, 4412697, 1100903, 1454521, 2223407, 6262439, 6305025, 414065, 6672794, 3471433, 4089706, 2592208, 1536046, 2462969, 3290424, 3050359, 1356310, 6967367, 3787669, 4189985, 5725180, 4731673, 922778, 3562581, 2891570, 5553192, 5643374, 1238959, 6179794, 2052193, 3095387, 2009488, 2867644, 4006442, 1280757, 3307920, 4643762, 5078585, 3367043, 1642889, 5665887, 2000205, 1605297, 4536868, 6733519, 968737, 5576790, 751477, 5691355, 3529294, 4197549, 6724279, 4151642, 3486211, 5773945, 137539, 924236, 5529719, 2541407, 3381211, 4486924, 4157314, 94891, 204037, 2397960, 4412697, 1100903, 1454521, 2223407, 6262439, 6305025, 414065, 6802623, 4769986, 1805696, 5760909, 2465850, 6135310, 3733013, 1228765, 1855625, 6588613, 181403, 1088322, 6725326, 3739395, 3283943, 5611178, 2022528, 6402688, 6124519, 3323907, 2324210, 4795389, 105697, 1792351, 5473883, 2378504, 1639254, 3618019, 77023, 354333, 3637398, 2500516, 59786, 4967829, 5024561, 5731121, 1911041, 6225675, 6808048, 5210605, 3730987, 2040069, 1495278, 4261514, 5352174, 117323, 2608536, 6539272, 2110328, 2462096, 1025914, 1430178, 2907394, 154192, 2929892, 521560, 6973751, 1451212, 1181496, 4757309, 5999731, 3557405, 1209711, 5317369, 6672794, 3471433, 4089706, 2592208, 1536046, 2462969, 3290424, 3050359, 1356310, 6967367, 3787669, 4189985, 5725180, 4731673, 922778, 3562581, 2891570, 5553192, 5643374, 1238959, 6179794, 2052193, 3095387, 2009488, 2867644, 4006442, 1280757, 3307920, 4643762, 5078585, 3367043, 1642889, 5665887, 2000205, 1605297, 4536868, 6733519, 968737, 5576790, 751477, 5691355, 3529294, 4197549, 6724279, 4151642, 3486211, 5773945, 137539, 924236, 5529719, 2541407, 3381211, 4486924, 4157314, 94891, 204037, 2397960, 4412697, 1100903, 1454521, 2223407, 6262439, 6305025, 414065, 6802623, 4769986, 1805696, 5760909, 2465850, 6135310, 3733013, 1228765, 1855625, 6588613, 181403, 1088322, 6725326, 3739395, 3283943, 5611178, 2022528, 6402688, 6124519, 3323907, 2324210, 4795389, 105697, 1792351, 5473883, 2378504, 1639254, 3618019, 77023, 354333, 3637398, 2500516, 59786, 4967829, 5024561, 5731121, 1911041, 6225675, 6808048, 5210605, 3730987, 2040069, 1495278, 4261514, 5352174, 117323, 2608536, 6539272, 2110328, 2462096, 1025914, 1430178, 2907394, 154192, 2929892, 521560, 6973751, 1451212, 1181496, 4757309, 5999731, 3557405, 1209711, 5317369, 3635970, 1321134, 200209, 5547177, 2278654, 996196, 2857757, 6062754, 4924818, 4767380, 502038, 2212528, 6064717, 3057683, 300404, 1152099, 2206084, 2099121, 2772451, 6115811, 5044627, 1370570, 5998865, 2235707, 3736822, 1606365, 6468161, 2350237, 2854985, 1719191, 1107849, 4119727, 6226245, 6072130, 2572353, 689654, 5594905, 6155813, 5467152, 702754, 531157, 6023336, 1415089, 2720529, 2874489, 4485149, 1823902, 1448837, 2586175, 6510033, 3827297, 393484, 4418580, 4016100, 2676380, 5191541, 6720554, 424245, 1379888, 772986, 415074, 6687062, 5065323, 6568702, 4953978, 2204982, 5586069, 2751330, 5345208, 1583075, 2208840, 4160096, 1761773, 6196033, 968429, 5200206, 2393162, 880438, 3556717, 611880, 1333711, 4413500, 2815827, 6216881, 5758985, 3080817, 1538998, 4548875, 714395, 1750587, 1960976, 4417253, 818724, 3939068, 1913461, 2257460, 2972966, 2936036, 460056, 1932437, 4887051, 3419919, 4525163, 2999191, 3295918, 1112301, 1490851, 3021365, 2133996, 5615176, 4597706, 6774640, 830671, 2429855, 6509143, 6636631, 5036374, 2565716, 1410605, 5570998, 3451694, 686943, 3944093, 5414932, 5611725, 3164056, 1746045, 4337982};
static const int32_t roots_inv[NTT_P - 1] = {6672794, 3512760, 4391985, 2894487, 3933834, 3693769, 4521224, 5448147, 3421612, 6061415, 2252520, 1259013, 2794208, 3196524, 16826, 5627883, 5341304, 3617150, 1905608, 2340431, 3676273, 5703436, 2977751, 4116549, 4974705, 3888806, 4932000, 804399, 5745234, 1340819, 1431001, 4092623, 6570128, 679168, 721754, 4760786, 5529672, 5883290, 2571496, 4586233, 6780156, 6889302, 2826879, 2497269, 3602982, 4442786, 1454474, 6059957, 6846654, 1210248, 3497982, 2832551, 259914, 2786644, 3454899, 1292838, 6232716, 1407403, 6015456, 250674, 2447325, 5378896, 4983988, 1318306, 1666824, 5774482, 3426788, 984462, 2226884, 5802697, 5532981, 10442, 6462633, 4054301, 6830001, 4076799, 5554015, 5958279, 4522097, 4873865, 444921, 4375657, 6866870, 1632019, 2722679, 5488915, 4944124, 3253206, 1773588, 176145, 758518, 5073152, 1253072, 1959632, 2016364, 6924407, 4483677, 3346795, 6629860, 6907170, 3366174, 5344939, 4605689, 1510310, 5191842, 6878496, 2188804, 4659983, 3660286, 859674, 581505, 4961665, 1373015, 3700250, 3244798, 258867, 5895871, 6802790, 395580, 5128568, 5755428, 3251180, 848883, 4518343, 1223284, 5178497, 2214207, 181570, 2646211, 5238148, 3820137, 1372468, 1569261, 3040100, 6297250, 3532499, 1413195, 5573588, 4418477, 1947819, 347562, 475050, 4554338, 6153522, 209553, 2386487, 1369017, 4850197, 3962828, 5493342, 5871892, 3688275, 3985002, 2459030, 3564274, 2097142, 5051756, 6524137, 4048157, 4011227, 4726733, 5070732, 3045125, 6165469, 2566940, 5023217, 5233606, 6269798, 2435318, 5445195, 3903376, 1225208, 767312, 4168366, 2570693, 5650482, 6372313, 3427476, 6103755, 4591031, 1783987, 6015764, 788160, 5222420, 2824097, 4775353, 5401118, 1638985, 4232863, 1398124, 4779211, 2030215, 415491, 1918870, 297131, 6569119, 6211207, 5604305, 6559948, 263639, 1792652, 4307813, 2968093, 2565613, 6590709, 3156896, 474160, 4398018, 5535356, 5160291, 2499044, 4109704, 4263664, 5569104, 960857, 6453036, 6281439, 1517041, 828380, 1389288, 6294539, 4411840, 912063, 757948, 2864466, 5876344, 5265002, 4129208, 4633956, 516032, 5377828, 3247371, 4748486, 985328, 5613623, 1939566, 868382, 4211742, 4885072, 4778109, 5832094, 6683789, 3926510, 919476, 4771665, 6482155, 2216813, 2059375, 921439, 4126436, 5987997, 4705539, 1437016, 6783984, 5663059, 3348223, 6672794, 3512760, 4391985, 2894487, 3933834, 3693769, 4521224, 5448147, 3421612, 6061415, 2252520, 1259013, 2794208, 3196524, 16826, 5627883, 5341304, 3617150, 1905608, 2340431, 3676273, 5703436, 2977751, 4116549, 4974705, 3888806, 4932000, 804399, 5745234, 1340819, 1431001, 4092623, 6570128, 679168, 721754, 4760786, 5529672, 5883290, 2571496, 4586233, 6780156, 6889302, 2826879, 2497269, 3602982, 4442786, 1454474, 6059957, 6846654, 1210248, 3497982, 2832551, 259914, 2786644, 3454899, 1292838, 6232716, 1407403, 6015456, 250674, 2447325, 5378896, 4983988, 1318306, 1666824, 5774482, 3426788, 984462, 2226884, 5802697, 5532981, 10442, 6462633, 4054301, 6830001, 4076799, 5554015, 5958279, 4522097, 4873865, 444921, 4375657, 6866870, 1632019, 2722679, 5488915, 4944124, 3253206, 1773588, 176145, 758518, 5073152, 1253072, 1959632, 2016364, 6924407, 4483677, 3346795, 6629860, 6907170, 3366174, 5344939, 4605689, 1510310, 5191842, 6878496, 2188804, 4659983, 3660286, 859674, 581505, 4961665, 1373015, 3700250, 3244798, 258867, 5895871, 6802790, 395580, 5128568, 5755428, 3251180, 848883, 4518343, 1223284, 5178497, 2214207, 181570, 6672794, 3512760, 4391985, 2894487, 3933834, 3693769, 4521224, 5448147, 3421612, 6061415, 2252520, 1259013, 2794208, 3196524, 16826, 5627883, 5341304, 3617150, 1905608, 2340431, 3676273, 5703436, 2977751, 4116549, 4974705, 3888806, 4932000, 804399, 5745234, 1340819, 1431001, 4092623, 6570128, 679168, 721754, 4760786, 5529672, 5883290, 2571496, 4586233, 6780156, 6889302, 2826879, 2497269, 3602982, 4442786, 1454474, 6059957, 6846654, 1210248, 3497982, 2832551, 259914, 2786644, 3454899, 1292838, 6232716, 1407403, 6015456, 250674, 2447325, 5378896, 4983988, 1318306, 6672794, 3512760, 4391985, 2894487, 3933834, 3693769, 4521224, 5448147, 3421612, 6061415, 2252520, 1259013, 2794208, 3196524, 16826, 5627883, 5341304, 3617150, 1905608, 2340431, 3676273, 5703436, 2977751, 4116549, 4974705, 3888806, 4932000, 804399, 5745234, 1340819, 1431001, 4092623, 6672794, 3512760, 4391985, 2894487, 3933834, 3693769, 4521224, 5448147, 3421612, 6061415, 2252520, 1259013, 2794208, 3196524, 16826, 5627883, 6672794, 3512760, 4391985, 2894487, 3933834, 3693769, 4521224, 5448147, 6672794, 3512760, 4391985, 2894487, 6672794, 3512760, 6672794};

static int32_t MR_top[NTT_P - 1] = {3336397, 3336397, 5227813, 3336397, 5227813, 2044853, 1296104, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 6325040, 4492199, 4294745, 2268434, 6858856, 3976465, 2788395, 3867835, 6337774, 1764647, 5590871, 6854236, 2075821, 5235202, 6379069, 3560866, 462118, 6256956, 4762800, 5182702, 2243462, 2078657, 3539542, 3594115, 1198980, 5698445, 4042548, 4219357, 4603800, 6623316, 6644609, 3699129, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 6325040, 4492199, 4294745, 2268434, 6858856, 3976465, 2788395, 3867835, 6337774, 1764647, 5590871, 6854236, 2075821, 5235202, 6379069, 3560866, 462118, 6256956, 4762800, 5182702, 2243462, 2078657, 3539542, 3594115, 1198980, 5698445, 4042548, 4219357, 4603800, 6623316, 6644609, 3699129, 6893408, 2384993, 902848, 6372551, 1232925, 3067655, 5358603, 4106479, 4419909, 6786403, 3582798, 544161, 3362663, 5361794, 5134068, 2805589, 1011264, 3201344, 6554356, 5154050, 1162105, 5889791, 3544945, 4388272, 6229038, 1189252, 819627, 5301106, 3530608, 3669263, 1818699, 1250258, 29893, 5976011, 6004377, 6357657, 4447617, 6604934, 3404024, 6097399, 5357590, 4512131, 747639, 2130757, 2676087, 3550758, 1304268, 3269636, 1055164, 1231048, 512957, 715089, 1453697, 77096, 1464946, 260780, 6978972, 725606, 590748, 5870751, 6491962, 5270799, 4096952, 6150781, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 6325040, 4492199, 4294745, 2268434, 6858856, 3976465, 2788395, 3867835, 6337774, 1764647, 5590871, 6854236, 2075821, 5235202, 6379069, 3560866, 462118, 6256956, 4762800, 5182702, 2243462, 2078657, 3539542, 3594115, 1198980, 5698445, 4042548, 4219357, 4603800, 6623316, 6644609, 3699129, 6893408, 2384993, 902848, 6372551, 1232925, 3067655, 5358603, 4106479, 4419909, 6786403, 3582798, 544161, 3362663, 5361794, 5134068, 2805589, 1011264, 3201344, 6554356, 5154050, 1162105, 5889791, 3544945, 4388272, 6229038, 1189252, 819627, 5301106, 3530608, 3669263, 1818699, 1250258, 29893, 5976011, 6004377, 6357657, 4447617, 6604934, 3404024, 6097399, 5357590, 4512131, 747639, 2130757, 2676087, 3550758, 1304268, 3269636, 1055164, 1231048, 512957, 715089, 1453697, 77096, 1464946, 260780, 6978972, 725606, 590748, 5870751, 6491962, 5270799, 4096952, 6150781, 1817985, 660567, 3592201, 6265685, 1139327, 498098, 4920975, 3031377, 2462409, 2383690, 251019, 1106264, 6524455, 5020938, 150202, 4068146, 1103042, 4541657, 4878322, 6550002, 6014410, 685285, 6491529, 4609950, 1868411, 4295279, 6726177, 4667215, 4919589, 4351692, 4046021, 5551960, 6605219, 3036065, 4778273, 344827, 6289549, 6570003, 2733576, 351377, 3757675, 3011668, 4199641, 4852361, 4929341, 5734671, 911951, 4216515, 4785184, 6747113, 5405745, 196742, 2209290, 2008050, 1338190, 6087867, 3360277, 3704219, 689944, 386493, 207537, 3343531, 6024758, 3284351, 2476989, 1102491, 6285131, 1375665, 2672604, 4283634, 1104420, 2080048, 4372983, 6590113, 3976311, 2600103, 1196581, 440219, 5270455, 305940, 4158952, 2206750, 4900010, 6600537, 6371589, 5032505, 769499, 5766534, 3849294, 4367390, 980488, 5700723, 409362, 1969534, 4448827, 1128730, 1486483, 1468018, 230028, 4458315, 5935622, 5202056, 5754678, 4991692, 1647959, 4048247, 4237522, 5002779, 1066998, 2807588, 2298853, 3387320, 3907432, 4707024, 6746668, 6810412, 2518187, 1282858, 4197399, 2785499, 1725847, 3835568, 5464143, 2707466, 6297959, 1582028, 4365119, 2168991};
static int32_t MR_bot[NTT_P - 1] = {2147483341, 2147483341, 1566747429, 2147483341, 1566747429, 1455684021, 1781757672, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 208610096, 852839847, 1581827673, 132274450, 149772392, 1476590353, 1054344747, 616980155, 1742534894, 1980804903, 657174871, 1560288860, 83296941, 1260305922, 388271165, 324268450, 417554726, 39010620, 2074889392, 889936110, 1447808902, 1437443521, 2082272854, 349970819, 661193604, 427985293, 748291892, 144857053, 1198624664, 748496980, 1535103361, 149352377, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 208610096, 852839847, 1581827673, 132274450, 149772392, 1476590353, 1054344747, 616980155, 1742534894, 1980804903, 657174871, 1560288860, 83296941, 1260305922, 388271165, 324268450, 417554726, 39010620, 2074889392, 889936110, 1447808902, 1437443521, 2082272854, 349970819, 661193604, 427985293, 748291892, 144857053, 1198624664, 748496980, 1535103361, 149352377, 455372640, 1803489889, 1681147584, 1798160071, 1746159133, 940757255, 903970315, 225204975, 946607941, 1846744931, 1861234510, 282885025, 950047079, 1243327618, 108998388, 2119062869, 363785792, 617240896, 578607860, 233275650, 1781578105, 844263679, 1863427441, 1745130928, 647548974, 1628757380, 1874262955, 1370349426, 1814560624, 1051422479, 1380907595, 60379090, 1730812613, 402090443, 1882348697, 87015577, 1573538689, 1948540038, 66486520, 1795435511, 1065432086, 1271276419, 1909295735, 2013604165, 2076243831, 1379959334, 137072332, 2140118020, 1937433020, 1407236296, 37226941, 133478225, 1701485697, 407919912, 160781938, 1233511084, 866092444, 1181279846, 1725041564, 1190979231, 1293417274, 786685711, 1942983608, 842305661, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 208610096, 852839847, 1581827673, 132274450, 149772392, 1476590353, 1054344747, 616980155, 1742534894, 1980804903, 657174871, 1560288860, 83296941, 1260305922, 388271165, 324268450, 417554726, 39010620, 2074889392, 889936110, 1447808902, 1437443521, 2082272854, 349970819, 661193604, 427985293, 748291892, 144857053, 1198624664, 748496980, 1535103361, 149352377, 455372640, 1803489889, 1681147584, 1798160071, 1746159133, 940757255, 903970315, 225204975, 946607941, 1846744931, 1861234510, 282885025, 950047079, 1243327618, 108998388, 2119062869, 363785792, 617240896, 578607860, 233275650, 1781578105, 844263679, 1863427441, 1745130928, 647548974, 1628757380, 1874262955, 1370349426, 1814560624, 1051422479, 1380907595, 60379090, 1730812613, 402090443, 1882348697, 87015577, 1573538689, 1948540038, 66486520, 1795435511, 1065432086, 1271276419, 1909295735, 2013604165, 2076243831, 1379959334, 137072332, 2140118020, 1937433020, 1407236296, 37226941, 133478225, 1701485697, 407919912, 160781938, 1233511084, 866092444, 1181279846, 1725041564, 1190979231, 1293417274, 786685711, 1942983608, 842305661, 2145528705, 1350989399, 1731964425, 439034197, 67826815, 1341396402, 288589967, 1340608337, 328790217, 1523592010, 891981451, 1954328920, 612847655, 2101405962, 667432634, 903843634, 2012098754, 222005977, 612789234, 1283190258, 194154954, 241294053, 190114697, 1524251550, 544234619, 1876180079, 973721633, 704784719, 1141241637, 56233676, 1146577605, 11831128, 1345573795, 2107015585, 594417441, 1334844667, 917606029, 1510435347, 1227433480, 1454680721, 168710251, 1113459796, 1462129369, 1089595529, 1320971581, 763556623, 1169349711, 114499779, 523158560, 1068896745, 154700337, 1741853830, 1054081546, 1722982386, 2001596238, 321404603, 1243434005, 268705691, 963565336, 1878137789, 1583626417, 120028843, 2021466678, 394637183, 451281341, 1173515419, 710222155, 1646267313, 1736789980, 592664818, 777015844, 1629117744, 1284103159, 1311161505, 1094110839, 1139175079, 1675307045, 189682075, 1522011575, 1836794644, 110175720, 964988958, 149278890, 1402860889, 1444830981, 1266829369, 4380635, 1641910662, 390217806, 473270302, 177104392, 340485747, 694287122, 1975005566, 897334331, 1638163738, 800381075, 985490034, 46639756, 1341735243, 1580148230, 2131873928, 1814496054, 1503384268, 853772119, 1794500471, 1724703954, 1345253403, 176290806, 1310740260, 1775008229, 413974456, 232935272, 791491280, 465689132, 398512940, 1170925227, 1542037290, 49344023, 53189339, 467679127, 826943152, 615273039, 218602506, 832133991, 258329548, 1163832639, 1702652575};

/* Provide function declarations */

extern void __asm_forward_ntt_setup(void);

extern void forward_layer_1(int32_t *coefficients, int32_t *MR_top, int32_t *MR_bot);

extern void forward_layer_2(int32_t *coefficients, int32_t *MR_top, int32_t *MR_bot);

extern void forward_layer_3(int32_t *coefficients, int32_t *MR_top, int32_t *MR_bot);

void forward_layer_4(int32_t *coefficients);

void forward_layer_5(int32_t *coefficients);

void forward_layer_6(int32_t *coefficients);

void forward_layer_7(int32_t *coefficients);

void forward_layer_8(int32_t *coefficients);

void forward_layer_9(int32_t *coefficients);

void inverse_layer_9(int32_t *coefficients);

void inverse_layer_8(int32_t *coefficients);

void inverse_layer_7(int32_t *coefficients);

void inverse_layer_6(int32_t *coefficients);

void inverse_layer_5(int32_t *coefficients);

void inverse_layer_4(int32_t *coefficients);

void inverse_layer_3(int32_t *coefficients);

void inverse_layer_2(int32_t *coefficients);

void inverse_layer_1(int32_t *coefficients);

void ntt_forward(int32_t *coefficients, int32_t mod);

void ntt_inverse(int32_t *coefficients, int32_t mod);

#endif
