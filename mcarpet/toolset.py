import os
import shutil
import tempfile
import logging
from mcarpet import measures
from mcarpet.utils import invoke
import pandas as pd
from cStringIO import StringIO


logger = logging.getLogger(__name__)


KNOWN_LANGUAGES = [
    'C',
    'C++'
    'Java',
    'python',
    'javascript',
    'Matlab',
    'R',
]


class QualityMeasuringTool(object):

    def __init__(self, name, languages, measures):
        self.__experiment = None
        self.name = name
        # Supported languages
        self.languages = languages
        # Supported measures
        self.measures = measures

    @property
    def experiment(self):
        if self.__experiment is None:
            raise Exception('This measurement tool has not been attached to '
                            'any experiment. See documentation for details.')
        return self.__experiment

    def attach_to_experiment(self, experiment):
        self.__experiment = experiment

    @staticmethod
    def list_quality_measuring_tools():
        '''Returns a list of available quality tools'''
        return [
            PmdTool(),
        ]

    def extract_measures(self, source_file_path):
        pass

    @property
    def tools_location_path(self):
        return os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            'tools',
        )

    def measure(self, product):
        '''
        Takes meta in passed software product to measure metrics using current
        tool implementation.
        '''


class PmdTool(QualityMeasuringTool):

    def __init__(self):
        QualityMeasuringTool.__init__(
            self,
            name='pmd',
            languages=['java'],
            measures=[measures.CC().name],
        )
        # MAP MC measures to PMD measures
        self.measures_map = {
            # measure -> ruleset
            measures.CC().name: 'CyclomaticComplexity',
        }
        # MAP PMD measures to rulesets
        self.ruleset_map = {
            'CyclomaticComplexity', 'java-codesize',
        }
        self.executable = os.path.join('pmd-bin-5.1.1', 'bin', 'run.sh')

    def get_ruleset(self, measure_name):
        return self.ruleset_map[self.measures_map[measure_name]]

    def measure_file(self, source_file_path):
        command = ('{executable} pmd -f csv -R {custom_ruleset} '
                   '-d {source_file_path}')
        command = command.format(
            executable=os.path.join(self.tools_location_path,
                                    self.executable),
            custom_ruleset=os.path.join(self.tools_location_path,
                                        'pmd-rulesets', 'java',
                                        'metricscarpet.xml'),
            source_file_path=source_file_path,
        )
        (stdoutdata, stderrdata) = invoke(command)
        self.process_data(pd.read_csv(StringIO(stdoutdata)))

    def process_data(self, raw_data_frame):
        '''
        We expect and parse PMD data in CSV format according to:

        "Problem","Package","File","Priority","Line","Description",
        "Rule set","Rule".

        In fact we just use pandas to make it straightforward.
        '''
        #
        # Adjust data columns and values as necessary.
        data_frame = raw_data_frame
        # Finally, collect the data by attached experiment.
        self.experiment.aggregate_frame(data_frame)


class MatlabTool(QualityMeasuringTool):

    def __init__(self):
        QualityMeasuringTool.__init__(
            self,
            name='matlab',
            languages=['matlab'],
            measures=[measures.CC().name],
        )
        # MAP MC measures to PMD measures
        self.measures_map = {
            # measure -> ruleset
            measures.CC().name: 'CyclomaticComplexity',
        }

    def get_ruleset(self, measure_name):
        return self.ruleset_map[self.measures_map[measure_name]]

    def measure(self, product):
        measures_filepath = os.path.join(tempfile.mkdtemp(), 'measures.mat')
        self.save_matlab_measures(product, measures_filepath)
        self.process_data(product, measures_filepath)
        logger.info('Cleaning up temporary files.')
        shutil.rmtree(os.path.dirname(measures_filepath))

    def save_matlab_measures(self, product, measures_filepath):
        logger.info('Measuring product: %s' % product.name)
        command = ('''$(which matlab) -nodisplay <<ENDOFCODE;
path('{matlab_tool_loc}', path());
measures = generateStats('{location}');
save('{measures_filepath}', 'measures', '-v7')
ENDOFCODE''')
        command = command.format(
            matlab_tool_loc=os.path.join(self.tools_location_path, 'matlab'),
            location=product._location,
            measures_filepath=measures_filepath,
        )
        (stdoutdata, stderrdata) = invoke(command)

    def process_data(self, product, measures_filepath):
        '''
        Use numpy to grab measures, generated by generateStats().
        '''
        logger.info('Processing data from MATLAB into a dataframe')
        import scipy.io
        data = scipy.io.loadmat(measures_filepath)
        rows = list()
        for row in data['measures']:
            line_counts = row[0][0][0][0]
            comments = row[0][1][0][0]
            cyclomatic_complexity = row[0][2][0][0]
            help_metric = row[0][3][0][0]
            filename = row[0][7][0]
            pathname = row[0][8][0]
            rows.append(
                (line_counts, comments, cyclomatic_complexity, help_metric,
                 filename, pathname),
            )
        data_frame = pd.DataFrame(
            rows,
            columns=('line_counts', 'comments', 'cyclomatic_complexity',
                     'help_metric', 'filename', 'pathname'),
        )
        logger.info('aggregating collected data frame into the experiment')
        self.experiment.aggregate_frame(data_frame)
