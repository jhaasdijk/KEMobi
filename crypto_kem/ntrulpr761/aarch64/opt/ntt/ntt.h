#ifndef NTT_H
#define NTT_H

/**
 * This header accompanies asm_ntt_forward.s and asm_ntt_inverse.s. It is used
 * to contain the wrappers for the forward and inverse iterative inplace NTT
 * transformations. As you can see it has been defined as a Once-Only Header to
 * avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <stdint.h>

/* Include user header files */

#include "ntt_params.h"

/* Define the precomputed (inverse) roots used in the NTT transformations */

static int32_t MR_top[NTT_P - 1] = {3336397, 3336397, 5227813, 3336397, 5227813, 2044853, 1296104, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 6325040, 4492199, 4294745, 2268434, 6858856, 3976465, 2788395, 3867835, 6337774, 1764647, 5590871, 6854236, 2075821, 5235202, 6379069, 3560866, 462118, 6256956, 4762800, 5182702, 2243462, 2078657, 3539542, 3594115, 1198980, 5698445, 4042548, 4219357, 4603800, 6623316, 6644609, 3699129, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 6325040, 4492199, 4294745, 2268434, 6858856, 3976465, 2788395, 3867835, 6337774, 1764647, 5590871, 6854236, 2075821, 5235202, 6379069, 3560866, 462118, 6256956, 4762800, 5182702, 2243462, 2078657, 3539542, 3594115, 1198980, 5698445, 4042548, 4219357, 4603800, 6623316, 6644609, 3699129, 6893408, 2384993, 902848, 6372551, 1232925, 3067655, 5358603, 4106479, 4419909, 6786403, 3582798, 544161, 3362663, 5361794, 5134068, 2805589, 1011264, 3201344, 6554356, 5154050, 1162105, 5889791, 3544945, 4388272, 6229038, 1189252, 819627, 5301106, 3530608, 3669263, 1818699, 1250258, 29893, 5976011, 6004377, 6357657, 4447617, 6604934, 3404024, 6097399, 5357590, 4512131, 747639, 2130757, 2676087, 3550758, 1304268, 3269636, 1055164, 1231048, 512957, 715089, 1453697, 77096, 1464946, 260780, 6978972, 725606, 590748, 5870751, 6491962, 5270799, 4096952, 6150781, 3336397, 5227813, 2044853, 1296104, 768023, 4723581, 1645212, 5017276, 678155, 6975780, 5385931, 5587089, 2862590, 5857933, 461389, 5273387, 1445785, 2776596, 2821687, 4111576, 3089897, 4518193, 5039790, 1004744, 1433822, 2003221, 4132475, 1653960, 2321881, 6031389, 5175618, 4313541, 6325040, 4492199, 4294745, 2268434, 6858856, 3976465, 2788395, 3867835, 6337774, 1764647, 5590871, 6854236, 2075821, 5235202, 6379069, 3560866, 462118, 6256956, 4762800, 5182702, 2243462, 2078657, 3539542, 3594115, 1198980, 5698445, 4042548, 4219357, 4603800, 6623316, 6644609, 3699129, 6893408, 2384993, 902848, 6372551, 1232925, 3067655, 5358603, 4106479, 4419909, 6786403, 3582798, 544161, 3362663, 5361794, 5134068, 2805589, 1011264, 3201344, 6554356, 5154050, 1162105, 5889791, 3544945, 4388272, 6229038, 1189252, 819627, 5301106, 3530608, 3669263, 1818699, 1250258, 29893, 5976011, 6004377, 6357657, 4447617, 6604934, 3404024, 6097399, 5357590, 4512131, 747639, 2130757, 2676087, 3550758, 1304268, 3269636, 1055164, 1231048, 512957, 715089, 1453697, 77096, 1464946, 260780, 6978972, 725606, 590748, 5870751, 6491962, 5270799, 4096952, 6150781, 1817985, 660567, 3592201, 6265685, 1139327, 498098, 4920975, 3031377, 2462409, 2383690, 251019, 1106264, 6524455, 5020938, 150202, 4068146, 1103042, 4541657, 4878322, 6550002, 6014410, 685285, 6491529, 4609950, 1868411, 4295279, 6726177, 4667215, 4919589, 4351692, 4046021, 5551960, 6605219, 3036065, 4778273, 344827, 6289549, 6570003, 2733576, 351377, 3757675, 3011668, 4199641, 4852361, 4929341, 5734671, 911951, 4216515, 4785184, 6747113, 5405745, 196742, 2209290, 2008050, 1338190, 6087867, 3360277, 3704219, 689944, 386493, 207537, 3343531, 6024758, 3284351, 2476989, 1102491, 6285131, 1375665, 2672604, 4283634, 1104420, 2080048, 4372983, 6590113, 3976311, 2600103, 1196581, 440219, 5270455, 305940, 4158952, 2206750, 4900010, 6600537, 6371589, 5032505, 769499, 5766534, 3849294, 4367390, 980488, 5700723, 409362, 1969534, 4448827, 1128730, 1486483, 1468018, 230028, 4458315, 5935622, 5202056, 5754678, 4991692, 1647959, 4048247, 4237522, 5002779, 1066998, 2807588, 2298853, 3387320, 3907432, 4707024, 6746668, 6810412, 2518187, 1282858, 4197399, 2785499, 1725847, 3835568, 5464143, 2707466, 6297959, 1582028, 4365119, 2168991};
static int32_t MR_bot[NTT_P - 1] = {2147483341, 2147483341, 1566747429, 2147483341, 1566747429, 1455684021, 1781757672, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 208610096, 852839847, 1581827673, 132274450, 149772392, 1476590353, 1054344747, 616980155, 1742534894, 1980804903, 657174871, 1560288860, 83296941, 1260305922, 388271165, 324268450, 417554726, 39010620, 2074889392, 889936110, 1447808902, 1437443521, 2082272854, 349970819, 661193604, 427985293, 748291892, 144857053, 1198624664, 748496980, 1535103361, 149352377, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 208610096, 852839847, 1581827673, 132274450, 149772392, 1476590353, 1054344747, 616980155, 1742534894, 1980804903, 657174871, 1560288860, 83296941, 1260305922, 388271165, 324268450, 417554726, 39010620, 2074889392, 889936110, 1447808902, 1437443521, 2082272854, 349970819, 661193604, 427985293, 748291892, 144857053, 1198624664, 748496980, 1535103361, 149352377, 455372640, 1803489889, 1681147584, 1798160071, 1746159133, 940757255, 903970315, 225204975, 946607941, 1846744931, 1861234510, 282885025, 950047079, 1243327618, 108998388, 2119062869, 363785792, 617240896, 578607860, 233275650, 1781578105, 844263679, 1863427441, 1745130928, 647548974, 1628757380, 1874262955, 1370349426, 1814560624, 1051422479, 1380907595, 60379090, 1730812613, 402090443, 1882348697, 87015577, 1573538689, 1948540038, 66486520, 1795435511, 1065432086, 1271276419, 1909295735, 2013604165, 2076243831, 1379959334, 137072332, 2140118020, 1937433020, 1407236296, 37226941, 133478225, 1701485697, 407919912, 160781938, 1233511084, 866092444, 1181279846, 1725041564, 1190979231, 1293417274, 786685711, 1942983608, 842305661, 2147483341, 1566747429, 1455684021, 1781757672, 1386519063, 664586621, 1338253980, 452810428, 1386222347, 747366692, 1619028171, 1862045329, 1564267006, 1010235533, 196681805, 1022882091, 1434111385, 1535833620, 182825015, 947621080, 653935593, 1685126961, 283749038, 67454152, 1591952606, 2000852757, 616228987, 1841245384, 2017962969, 1450016285, 475747650, 1382119365, 208610096, 852839847, 1581827673, 132274450, 149772392, 1476590353, 1054344747, 616980155, 1742534894, 1980804903, 657174871, 1560288860, 83296941, 1260305922, 388271165, 324268450, 417554726, 39010620, 2074889392, 889936110, 1447808902, 1437443521, 2082272854, 349970819, 661193604, 427985293, 748291892, 144857053, 1198624664, 748496980, 1535103361, 149352377, 455372640, 1803489889, 1681147584, 1798160071, 1746159133, 940757255, 903970315, 225204975, 946607941, 1846744931, 1861234510, 282885025, 950047079, 1243327618, 108998388, 2119062869, 363785792, 617240896, 578607860, 233275650, 1781578105, 844263679, 1863427441, 1745130928, 647548974, 1628757380, 1874262955, 1370349426, 1814560624, 1051422479, 1380907595, 60379090, 1730812613, 402090443, 1882348697, 87015577, 1573538689, 1948540038, 66486520, 1795435511, 1065432086, 1271276419, 1909295735, 2013604165, 2076243831, 1379959334, 137072332, 2140118020, 1937433020, 1407236296, 37226941, 133478225, 1701485697, 407919912, 160781938, 1233511084, 866092444, 1181279846, 1725041564, 1190979231, 1293417274, 786685711, 1942983608, 842305661, 2145528705, 1350989399, 1731964425, 439034197, 67826815, 1341396402, 288589967, 1340608337, 328790217, 1523592010, 891981451, 1954328920, 612847655, 2101405962, 667432634, 903843634, 2012098754, 222005977, 612789234, 1283190258, 194154954, 241294053, 190114697, 1524251550, 544234619, 1876180079, 973721633, 704784719, 1141241637, 56233676, 1146577605, 11831128, 1345573795, 2107015585, 594417441, 1334844667, 917606029, 1510435347, 1227433480, 1454680721, 168710251, 1113459796, 1462129369, 1089595529, 1320971581, 763556623, 1169349711, 114499779, 523158560, 1068896745, 154700337, 1741853830, 1054081546, 1722982386, 2001596238, 321404603, 1243434005, 268705691, 963565336, 1878137789, 1583626417, 120028843, 2021466678, 394637183, 451281341, 1173515419, 710222155, 1646267313, 1736789980, 592664818, 777015844, 1629117744, 1284103159, 1311161505, 1094110839, 1139175079, 1675307045, 189682075, 1522011575, 1836794644, 110175720, 964988958, 149278890, 1402860889, 1444830981, 1266829369, 4380635, 1641910662, 390217806, 473270302, 177104392, 340485747, 694287122, 1975005566, 897334331, 1638163738, 800381075, 985490034, 46639756, 1341735243, 1580148230, 2131873928, 1814496054, 1503384268, 853772119, 1794500471, 1724703954, 1345253403, 176290806, 1310740260, 1775008229, 413974456, 232935272, 791491280, 465689132, 398512940, 1170925227, 1542037290, 49344023, 53189339, 467679127, 826943152, 615273039, 218602506, 832133991, 258329548, 1163832639, 1702652575};

static int32_t MR_inv_top[NTT_P - 1] = {3336397, 1756380, 5688089, 4939340, 1966917, 5338981, 2260612, 6216170, 1710806, 6522804, 1126260, 4121603, 1397104, 1598262, 8413, 6306038, 2670652, 1808575, 952804, 4662312, 5330233, 2851718, 4980972, 5550371, 5979449, 1944403, 2466000, 3894296, 2872617, 4162506, 4207597, 5538408, 3285064, 339584, 360877, 2380393, 2764836, 2941645, 1285748, 5785213, 3390078, 3444651, 4905536, 4740731, 1801491, 2221393, 727237, 6522075, 3423327, 605124, 1748991, 4908372, 129957, 1393322, 5219546, 646419, 3116358, 4195798, 3007728, 125337, 4715759, 2689448, 2491994, 659153, 833412, 2887241, 1713394, 492231, 1113442, 6393445, 6258587, 5221, 6723413, 5519247, 6907097, 5530496, 6269104, 6471236, 5753145, 5929029, 3714557, 5679925, 3433435, 4308106, 4853436, 6236554, 2472062, 1626603, 886794, 3580169, 379259, 2536576, 626536, 979816, 1008182, 6954300, 5733935, 5165494, 3314930, 3453585, 1683087, 6164566, 5794941, 755155, 2595921, 3439248, 1094402, 5822088, 1830143, 429837, 3782849, 5972929, 4178604, 1850125, 1622399, 3621530, 6440032, 3401395, 197790, 2564284, 2877714, 1625590, 3916538, 5751268, 611642, 6081345, 4599200, 90785, 4815202, 2619074, 5402165, 686234, 4276727, 1520050, 3148625, 5258346, 4198694, 2786794, 5701335, 4466006, 173781, 237525, 2277169, 3076761, 3596873, 4685340, 4176605, 5917195, 1981414, 2746671, 2935946, 5336234, 1992501, 1229515, 1782137, 1048571, 2525878, 6754165, 5516175, 5497710, 5855463, 2535366, 5014659, 6574831, 1283470, 6003705, 2616803, 3134899, 1217659, 6214694, 1951688, 612604, 383656, 2084183, 4777443, 2825241, 6678253, 1713738, 6543974, 5787612, 4384090, 3007882, 394080, 2611210, 4904145, 5879773, 2700559, 4311589, 5608528, 699062, 5881702, 4507204, 3699842, 959435, 3640662, 6776656, 6597700, 6294249, 3279974, 3623916, 896326, 5646003, 4976143, 4774903, 6787451, 1578448, 237080, 2199009, 2767678, 6072242, 1249522, 2054852, 2131832, 2784552, 3972525, 3226518, 6632816, 4250617, 414190, 694644, 6639366, 2205920, 3948128, 378974, 1432233, 2938172, 2632501, 2064604, 2316978, 258016, 2688914, 5115782, 2374243, 492664, 6298908, 969783, 434191, 2105871, 2442536, 5881151, 2916047, 6833991, 1963255, 459738, 5877929, 6733174, 4600503, 4521784, 3952816, 2063218, 6486095, 5844866, 718508, 3391992, 6323626, 5166208, 3336397, 1756380, 5688089, 4939340, 1966917, 5338981, 2260612, 6216170, 1710806, 6522804, 1126260, 4121603, 1397104, 1598262, 8413, 6306038, 2670652, 1808575, 952804, 4662312, 5330233, 2851718, 4980972, 5550371, 5979449, 1944403, 2466000, 3894296, 2872617, 4162506, 4207597, 5538408, 3285064, 339584, 360877, 2380393, 2764836, 2941645, 1285748, 5785213, 3390078, 3444651, 4905536, 4740731, 1801491, 2221393, 727237, 6522075, 3423327, 605124, 1748991, 4908372, 129957, 1393322, 5219546, 646419, 3116358, 4195798, 3007728, 125337, 4715759, 2689448, 2491994, 659153, 833412, 2887241, 1713394, 492231, 1113442, 6393445, 6258587, 5221, 6723413, 5519247, 6907097, 5530496, 6269104, 6471236, 5753145, 5929029, 3714557, 5679925, 3433435, 4308106, 4853436, 6236554, 2472062, 1626603, 886794, 3580169, 379259, 2536576, 626536, 979816, 1008182, 6954300, 5733935, 5165494, 3314930, 3453585, 1683087, 6164566, 5794941, 755155, 2595921, 3439248, 1094402, 5822088, 1830143, 429837, 3782849, 5972929, 4178604, 1850125, 1622399, 3621530, 6440032, 3401395, 197790, 2564284, 2877714, 1625590, 3916538, 5751268, 611642, 6081345, 4599200, 90785, 3336397, 1756380, 5688089, 4939340, 1966917, 5338981, 2260612, 6216170, 1710806, 6522804, 1126260, 4121603, 1397104, 1598262, 8413, 6306038, 2670652, 1808575, 952804, 4662312, 5330233, 2851718, 4980972, 5550371, 5979449, 1944403, 2466000, 3894296, 2872617, 4162506, 4207597, 5538408, 3285064, 339584, 360877, 2380393, 2764836, 2941645, 1285748, 5785213, 3390078, 3444651, 4905536, 4740731, 1801491, 2221393, 727237, 6522075, 3423327, 605124, 1748991, 4908372, 129957, 1393322, 5219546, 646419, 3116358, 4195798, 3007728, 125337, 4715759, 2689448, 2491994, 659153, 3336397, 1756380, 5688089, 4939340, 1966917, 5338981, 2260612, 6216170, 1710806, 6522804, 1126260, 4121603, 1397104, 1598262, 8413, 6306038, 2670652, 1808575, 952804, 4662312, 5330233, 2851718, 4980972, 5550371, 5979449, 1944403, 2466000, 3894296, 2872617, 4162506, 4207597, 5538408, 3336397, 1756380, 5688089, 4939340, 1966917, 5338981, 2260612, 6216170, 1710806, 6522804, 1126260, 4121603, 1397104, 1598262, 8413, 6306038, 3336397, 1756380, 5688089, 4939340, 1966917, 5338981, 2260612, 6216170, 3336397, 1756380, 5688089, 4939340, 3336397, 1756380, 3336397};
static int32_t MR_inv_bot[NTT_P - 1] = {2147483341, 580736220, 365725977, 691799628, 1694673221, 809229669, 1482897028, 760964586, 1124601558, 1950801844, 1137248116, 583216643, 285438320, 528455478, 1400116957, 761261302, 765364284, 1671735999, 697467364, 129520680, 306238265, 1531254662, 146630892, 555531043, 2080029497, 1863734611, 462356688, 1493548056, 1199862569, 1964658634, 611650029, 713372264, 1998131272, 612380288, 1398986669, 948858985, 2002626596, 1399191757, 1719498356, 1486290045, 1797512830, 65210795, 710040128, 699674747, 1257547539, 72594257, 2108473029, 1729928923, 1823215199, 1759212484, 887177727, 2064186708, 587194789, 1490308778, 166678746, 404948755, 1530503494, 1093138902, 670893296, 1997711257, 2015209199, 565655976, 1294643802, 1938873553, 1305177988, 204500041, 1360797938, 854066375, 956504418, 422442085, 966203803, 1281391205, 913972565, 1986701711, 1739563737, 445997952, 2014005424, 2110256708, 740247353, 210050629, 7365629, 2010411317, 767524315, 71239818, 133879484, 238187914, 876207230, 1082051563, 352048138, 2080997129, 198943611, 573944960, 2060468072, 265134952, 1745393206, 416671036, 2087104559, 766576054, 1096061170, 332923025, 777134223, 273220694, 518726269, 1499934675, 402352721, 284056208, 1303219970, 365905544, 1914207999, 1568875789, 1530242753, 1783697857, 28420780, 2038485261, 904156031, 1197436570, 1864598624, 286249139, 300738718, 1200875708, 1922278674, 1243513334, 1206726394, 401324516, 349323578, 466336065, 343993760, 1692111009, 444831074, 983651010, 1889154101, 1315349658, 1928881143, 1532210610, 1320540497, 1679804522, 2094294310, 2098139626, 605446359, 976558422, 1748970709, 1681794517, 1355992369, 1914548377, 1733509193, 372475420, 836743389, 1971192843, 802230246, 422779695, 352983178, 1293711530, 644099381, 332987595, 15609721, 567335419, 805748406, 2100843893, 1161993615, 1347102574, 509319911, 1250149318, 172478083, 1453196527, 1806997902, 1970379257, 1674213347, 1757265843, 505572987, 2143103014, 880654280, 702652668, 744622760, 1998204759, 1182494691, 2037307929, 310689005, 625472074, 1957801574, 472176604, 1008308570, 1053372810, 836322144, 863380490, 518365905, 1370467805, 1554818831, 410693669, 501216336, 1437261494, 973968230, 1696202308, 1752846466, 126016971, 2027454806, 563857232, 269345860, 1183918313, 1878777958, 904049644, 1826079046, 145887411, 424501263, 1093402103, 405629819, 1992783312, 1078586904, 1624325089, 2032983870, 978133938, 1383927026, 826512068, 1057888120, 685354280, 1034023853, 1978773398, 692802928, 920050169, 637048302, 1229877620, 812638982, 1553066208, 40468064, 801909854, 2135652521, 1000906044, 2091249973, 1006242012, 1442698930, 1173762016, 271303570, 1603249030, 623232099, 1957368952, 1906189596, 1953328695, 864293391, 1534694415, 1925477672, 135384895, 1243640015, 1480051015, 46077687, 1534635994, 193154729, 1255502198, 623891639, 1818693432, 806875312, 1858893682, 806087247, 2079656834, 1708449452, 415519224, 796494250, 1954944, 2147483341, 580736220, 365725977, 691799628, 1694673221, 809229669, 1482897028, 760964586, 1124601558, 1950801844, 1137248116, 583216643, 285438320, 528455478, 1400116957, 761261302, 765364284, 1671735999, 697467364, 129520680, 306238265, 1531254662, 146630892, 555531043, 2080029497, 1863734611, 462356688, 1493548056, 1199862569, 1964658634, 611650029, 713372264, 1998131272, 612380288, 1398986669, 948858985, 2002626596, 1399191757, 1719498356, 1486290045, 1797512830, 65210795, 710040128, 699674747, 1257547539, 72594257, 2108473029, 1729928923, 1823215199, 1759212484, 887177727, 2064186708, 587194789, 1490308778, 166678746, 404948755, 1530503494, 1093138902, 670893296, 1997711257, 2015209199, 565655976, 1294643802, 1938873553, 1305177988, 204500041, 1360797938, 854066375, 956504418, 422442085, 966203803, 1281391205, 913972565, 1986701711, 1739563737, 445997952, 2014005424, 2110256708, 740247353, 210050629, 7365629, 2010411317, 767524315, 71239818, 133879484, 238187914, 876207230, 1082051563, 352048138, 2080997129, 198943611, 573944960, 2060468072, 265134952, 1745393206, 416671036, 2087104559, 766576054, 1096061170, 332923025, 777134223, 273220694, 518726269, 1499934675, 402352721, 284056208, 1303219970, 365905544, 1914207999, 1568875789, 1530242753, 1783697857, 28420780, 2038485261, 904156031, 1197436570, 1864598624, 286249139, 300738718, 1200875708, 1922278674, 1243513334, 1206726394, 401324516, 349323578, 466336065, 343993760, 1692111009, 2147483341, 580736220, 365725977, 691799628, 1694673221, 809229669, 1482897028, 760964586, 1124601558, 1950801844, 1137248116, 583216643, 285438320, 528455478, 1400116957, 761261302, 765364284, 1671735999, 697467364, 129520680, 306238265, 1531254662, 146630892, 555531043, 2080029497, 1863734611, 462356688, 1493548056, 1199862569, 1964658634, 611650029, 713372264, 1998131272, 612380288, 1398986669, 948858985, 2002626596, 1399191757, 1719498356, 1486290045, 1797512830, 65210795, 710040128, 699674747, 1257547539, 72594257, 2108473029, 1729928923, 1823215199, 1759212484, 887177727, 2064186708, 587194789, 1490308778, 166678746, 404948755, 1530503494, 1093138902, 670893296, 1997711257, 2015209199, 565655976, 1294643802, 1938873553, 2147483341, 580736220, 365725977, 691799628, 1694673221, 809229669, 1482897028, 760964586, 1124601558, 1950801844, 1137248116, 583216643, 285438320, 528455478, 1400116957, 761261302, 765364284, 1671735999, 697467364, 129520680, 306238265, 1531254662, 146630892, 555531043, 2080029497, 1863734611, 462356688, 1493548056, 1199862569, 1964658634, 611650029, 713372264, 2147483341, 580736220, 365725977, 691799628, 1694673221, 809229669, 1482897028, 760964586, 1124601558, 1950801844, 1137248116, 583216643, 285438320, 528455478, 1400116957, 761261302, 2147483341, 580736220, 365725977, 691799628, 1694673221, 809229669, 1482897028, 760964586, 2147483341, 580736220, 365725977, 691799628, 2147483341, 580736220, 2147483341};

/**
 * @brief Compute the iterative inplace forward NTT of a polynomial.
 *
 * @details This function can be used to compute the iterative inplace forward
 * NTT of a polynomial represented by its integer coefficients. It wraps the
 * earlier defined per-layer forward transformations into a single, easy to use
 * function.
 *
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] MR_top The precomputed roots (B)
 * @param[in] MR_bot The precomputed roots (B')
 */
extern void __asm_ntt_forward(int32_t *coefficients, int32_t *MR_top, int32_t *MR_bot);

/**
 * @brief Compute the iterative inplace inverse NTT of a polynomial.
 *
 * @details This function can be used to compute the iterative inplace inverse
 * NTT of a polynomial represented by its integer coefficients. It wraps the
 * earlier defined per-layer inverse transformations into a single, easy to use
 * function.
 *
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] MR_inv_top The precomputed inverse roots (B)
 * @param[in] MR_inv_bot The precomputed inverse roots (B')
 */
extern void __asm_ntt_inverse(int32_t *coefficients, int32_t *MR_inv_top, int32_t *MR_inv_bot);

/**
 * @brief Ensure that the coefficients stay within their allocated 32 bits
 *
 * Due to how the inverse NTT transformation is calculated, each layer increases
 * the possible bitsize of the integer coefficients by 1. Performing 9 layers
 * increases the possible bitsize of the integer coefficients by 9. To ensure
 * that the integer coefficients stay within their allocated 32 bits we either
 * 1) need to ensure that all values are at most 23 bits at the start of the
 * function or 2) perform an intermediate reduction.
 *
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 */
extern void __asm_reduce_coefficients(int32_t *coefficients);
extern void __asm_reduce_multiply(int32_t *coefficients);

#endif
